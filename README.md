# Do Large Language Models Understand Data Visualization Rules?

> Proceedings of the Latinx in AI Workshop @ NeurIPS 2025  
> **Martín Sinnona, Valentín Bonás, Emmanuel Iarussi, Viviana Siless**  
> Universidad Torcuato Di Tella · CONICET · Universidad de Buenos Aires  

[![arXiv](https://img.shields.io/badge/arXiv-Read%20Paper-b31b1b.svg)](https://arxiv.org/abs/XXXX.XXXXX)
[![Corpus](https://img.shields.io/badge/Corpus-Browse%20on%20GitHub-28a745.svg)](docs/principles.md)

---

## Abstract

Data visualization rules—derived from decades of research in design and perception—ensure trustworthy chart communication. While prior work has shown that large language models (LLMs) can generate charts or flag misleading figures, it remains unclear whether they can reason about and enforce visualization rules directly. Constraint-based systems such as Draco encode these rules as logical constraints for precise automated checks, but maintaining symbolic encodings requires expert effort, motivating the use of LLMs as flexible rule validators.

In this paper, we present the first systematic evaluation of LLMs against visualization rules using hard-verification ground truth derived from Answer Set Programming (ASP). We translated a subset of Draco’s constraints into natural-language statements and generated a controlled dataset of 2,000 Vega-Lite specifications annotated with explicit rule violations. LLMs were evaluated on both accuracy in detecting violations and prompt adherence, which measures whether outputs follow the required structured format.

Results show that frontier models achieve high adherence (Gemma 3 4B / 27B: 100%, GPT-OSS 20B: 98%) and reliably detect common violations (F1 up to 0.82), yet performance drops for subtler perceptual rules (F1 < 0.15 for some categories) and for outputs generated from technical ASP formulations. Translating constraints into natural language improved performance by up to 150% for smaller models.

These findings demonstrate the potential of LLMs as flexible, language-driven validators while highlighting their current limitations compared to symbolic solvers.

---

## Key Contributions

- ✅ First hard-verification benchmark evaluating LLMs against ASP-based visualization constraints  
- 📊 A synthetic dataset of 2,000 Vega-Lite specifications annotated with solver-verified rule violations  
- 🧠 Comparison between ASP-formulated rules and natural-language rule translations  
- 📏 Evaluation across multiple open-source LLMs with structured prompt adherence metrics  
- 📈 Detailed per-category F1 evaluation (encoding, mark, stack, scale, data)

---

## Evaluation Overview

We evaluate whether LLMs can:

1. Detect visualization rule violations directly from Vega-Lite specifications  
2. Follow strict structured output formats (prompt adherence)  
3. Generalize across multiple categories of visualization principles  

### Evaluation Pipeline

1. Random chart generation  
2. Draco-based ground-truth violation detection  
3. KL-divergence filtering for balanced rule distribution  
4. Structured LLM prompting (5 variants)  
5. Multi-run inference with averaged metrics  

---

## Main Findings

- Frontier models (e.g., GPT-OSS 20B) significantly outperform smaller models.
- Prompt adherence is a critical prerequisite for reliable evaluation.
- Natural-language rule descriptions dramatically improve LLM performance compared to raw ASP formulations.
- LLMs struggle with subtle perceptual rules despite strong performance on structural ones.

---

## Citation

If you use this work, please cite:

```bibtex
@inproceedings{sinnona2025llmvisrules,
}


