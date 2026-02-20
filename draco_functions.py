from draco import dict_to_facts, schema_from_dataframe, schema_from_file, Draco
import pandas as pd
import pprint
import altair as alt
from vega_datasets import data as vega_data
import draco as drc
from IPython.display import Markdown, display
from draco.renderer import AltairRenderer
import random
from altair.utils.schemapi import SchemaValidationError
import wandb
import numpy as np

def recommend_charts(
    spec: list[str],
    draco: drc.Draco,
    dataset: pd.DataFrame,
    num: int = 5,
    labeler=lambda i: f"CHART {i + 1}"
) -> dict[str, dict]:
    chart_specs = {}
    renderer = AltairRenderer()
    for i, model in enumerate(draco.complete_spec(spec, num)):
        chart_name = labeler(i)
        spec_dict = drc.answer_set_to_dict(model.answer_set)
        spec_dict.setdefault("view", {})
        # print(chart_name)
        # print(f"COST: {model.cost}")
        chart = renderer.render(spec=spec_dict, data=dataset)
        # Adjust column-faceted chart size
        if (
            isinstance(chart, alt.FacetChart)
            and chart.facet.column is not alt.Undefined
        ):
            chart = chart.configure_view(continuousWidth=130, continuousHeight=130)
        # display(chart)

        chart_specs[chart_name] = {
            "cost":     model.cost,
            "spec":     spec_dict,
            "facts":    drc.dict_to_facts(spec_dict),
        }
    return chart_specs


def rec_from_generated_spec(marks: list[str], fields: list[str], encoding_channels: list[str], draco: drc.Draco, input_spec_base, dataset, num: int = 1) -> dict[str, dict]:
    input_spec_base = input_spec_base + [
        'entity(view,root,v0).',
        'entity(mark,v0,m0).',
    ]

    input_specs = [((mark, field, enc_ch), input_spec_base + 
        [f"attribute((mark,type),m0,{mark}).",
         "entity(encoding,m0,e0).",
         f"attribute((encoding,field),e0,{field}).",
         f"attribute((encoding,channel),e0,{enc_ch})."]
        )
        for mark in marks
        for field in fields
        for enc_ch in encoding_channels
    ]

    all_recs = {}
    lowest = None
    highest = None

    for cfg, spec in input_specs:
        def labeler(i):
            return f"CHART ({' | '.join(cfg)})"

        aux = recommend_charts(spec=spec, draco=draco, dataset=dataset, num=num, labeler=labeler)

        for label, chart_info in aux.items():
            cost = chart_info["cost"]
            all_recs[label] = chart_info

            if lowest is None or cost < lowest[1]["cost"]:
                lowest = (label, chart_info)
            if highest is None or cost > highest[1]["cost"]:
                highest = (label, chart_info)

    # Sort recommendations by cost (ascending)
    sorted_recs = dict(sorted(all_recs.items(), key=lambda item: item[1]["cost"]))

    return {
        "recommendations": sorted_recs,
        "lowest_cost": lowest,
        "highest_cost": highest
    }

def generate_charts(chosen_fields, chosen_enc, chosen_scales, chosen_mark, chosen_extra, chosen_agg=None, chosen_stack=None, use_polar=False):
    """
    Build a single Draco spec with optional aggregation, stacking, and polar coordinates.

    Parameters:
      - chosen_fields : List of field names, e.g. ["Sepal.Length","Species"]
      - chosen_enc    : List of channels,    e.g. ["x","color"]
      - chosen_scales : List of scale types, e.g. ["linear","ordinal"]
      - chosen_mark   : One of ["bar","line","point",…]
      - chosen_extra  : One of ["aggregate", "stack", "None"]
      - chosen_agg    : Aggregation function to use if chosen_extra == "aggregate"
      - chosen_stack  : Stack mode to use if chosen_extra == "stack"
      - use_polar     : If True, adds "coordinates": "polar" to the view
    """
    encodings = []
    scales = []

    for i, (field, channel, scale) in enumerate(zip(chosen_fields, chosen_enc, chosen_scales)):
        encoding = {
            "channel": channel,
            "field": field
        }

        # Apply extra feature only to the first encoding
        if i == 0:
            if chosen_extra == "aggregate":
                encoding["aggregate"] = chosen_agg
            elif chosen_extra == "stack":
                encoding["stack"] = chosen_stack

        encodings.append(encoding)

        scale_dict = {
            "channel": channel,
            "type": scale
        }

        # Optionally add "zero": "true" for y-axis linear scale (as in your polar example)
        if scale == "linear" and channel == "y":
            scale_dict["zero"] = True

        scales.append(scale_dict)

    view = {
        "mark": [
            {
                "type": chosen_mark,
                "encoding": encodings
            }
        ],
        "scale": scales
    }

    if use_polar:
        view["coordinates"] = "polar"

    draco_spec = {
        "view": [view]
    }

    return draco_spec

def generate_charts_from_vector(vector):
    """
    Build a single Draco spec from a dictionary-style vector of chart parameters.

    Parameters:
      - vector : Dictionary with the following keys:
        - "num_of_encoding": int
        - "fields": list of strings (length 3, use only first N)
        - "encodings": list of strings (length 3, use only first N)
        - "scales": list of strings (length 3, use only first N)
        - "mark": string
        - "extra": "aggregate", "stack", or "None"
        - "aggregate": string or None
        - "stack": string or None
    """
    encodings = []
    scales = []

    num_enc = vector["num_of_encoding"]

    for i in range(num_enc):
        field = vector["fields"][i]
        channel = vector["encodings"][i]
        scale_type = vector["scales"][i]

        encoding = {
            "channel": channel,
            "field": field
        }

        if i == 0:
            if vector["extra"] == "aggregate":
                encoding["aggregate"] = vector["aggregate"]
            elif vector["extra"] == "stack":
                encoding["stack"] = vector["stack"]

        encodings.append(encoding)

        scales.append({
            "channel": channel,
            "type": scale_type
        })

    draco_spec = {
        "view": [
            {
                "mark": [
                    {
                        "type": vector["mark"],
                        "encoding": encodings
                    }
                ],
                "scale": scales
            }
        ]
    }

    return draco_spec


def generate_valid_specs(
    df,
    num_runs=1000,
    num_of_encoding=[2, 3],
    fields=None,
    encodings=None,
    scales=None,
    marks=None,
    extra=None,
    aggregates=None,
    stacks=None,
    problem_count=None,  # <- inject externally tracked dictionary
    upload_wandb=False
):
    d = Draco()
    data_schema = schema_from_dataframe(df)
    if problem_count is None:
        raise ValueError("You must provide an initialized problem_count dictionary.")

    results = []
    i = 0

    while i < num_runs:

        count = sum(np.array(list(problem_count.values())) > 0)
        if upload_wandb: wandb.log({"iter": i, marks[0] + "_problems_count": count})

        try:
            enc_num = random.choice(num_of_encoding)

            chosen_fields = random.sample(fields, k=enc_num)
            chosen_enc = random.sample(encodings, k=enc_num)
            chosen_scales = random.choices(scales, k=enc_num)
            chosen_mark = random.choice(marks)
            chosen_extra = random.choice(extra)
            chosen_agg = random.choice(aggregates)
            chosen_stack = random.choice(stacks)

            spec = generate_charts(
                chosen_fields, chosen_enc, chosen_scales,
                chosen_mark, chosen_extra, chosen_agg, chosen_stack
            ) | data_schema

            try:
                chart = AltairRenderer().render(spec, df)
                _ = chart.to_dict(validate=True)
                _ = chart.to_json()
            except SchemaValidationError as e:
                # print(f"Schema error — drop this chart: {e}")
                continue
            except Exception as e:
                # print(f"Other render error — drop this chart: {e}")
                continue

            facts = dict_to_facts(spec)
            hards = d.get_violations(facts)
            softs = dict(d.count_preferences(facts))

            # Increment only problems listed in problem_count
            for h in hards:
                if h in problem_count:
                    problem_count[h] += 1

            for s, count in softs.items():
                if s in problem_count:
                    problem_count[s] += count

            results.append({
                "spec": spec,
                "hard": [h for h in hards if h in problem_count],
                "soft": {s: count for s, count in softs.items() if s in problem_count}
            })

            print(f"Run {i}: {len(hards)} hard, {sum(softs.values())} soft")

        except Exception as e:
            print(f"Run {i} failed:", e)

        i += 1

    return results, problem_count
