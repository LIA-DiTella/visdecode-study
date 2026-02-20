% @hard(size_negative) Do not use size when data is negative as size implies that data is positive.
violation(size_negative) :-
    attribute((encoding,channel),E,size),
    helper((encoding,field),E,F),
    attribute((field,min),F,MIN),
    attribute((field,max),F,MAX),
    MIN < 0,
    MAX > 0.

% @hard(line_area_with_discrete) Line and area cannot have both x and y discrete.
violation(line_area_with_discrete) :-
    attribute((mark,type),M,(line;area)),
    helper(mark_scale_channel,M,T1,x),
    helper(mark_scale_channel,M,T2,y),
    domain(discrete_scale,T1),
    domain(discrete_scale,T2).

% @hard(bar_tick_continuous_x_y) Bar and tick cannot have both x and y continuous.
violation(bar_tick_continuous_x_y) :-
    attribute((mark,type),M,(tick;bar)),
    helper(is_c_c,M).

% @hard(shape_without_point) Shape channel requires point mark.
violation(shape_without_point) :-
    helper((mark,channel),M,shape),
    not attribute((mark,type),M,point).

% @hard(size_without_point_text) Size only works with some marks.
violation(size_without_point_text) :-
    helper((mark,channel),M,size),
    not attribute((mark,type),M,text),
    not attribute((mark,type),M,point).

% @hard(area_bar_with_log) Do not use log for bar or area mark as they are often misleading. We may remove this rule in the future.
violation(area_bar_with_log) :-
    attribute((mark,type),M,(bar;area)),
    helper(mark_scale_channel,M,log,(x;y)).

% @hard(rect_without_d_d) Rect mark needs discrete x and y.
violation(rect_without_d_d) :-
    attribute((mark,type),M,rect),
    helper(mark_scale_channel,M,T,(x;y)),
    domain(continuous_scale,T).

% @hard(same_field_x_and_y) Don't use the same field on x and y.
violation(same_field_x_and_y) :-
    helper(mark_channel_field,M,x,F),
    helper(mark_channel_field,M,y,F),
    entity(field,root,F),
    entity(mark,_,M).

% @hard(bar_tick_area_line_without_continuous_x_y) Bar, tick, line, area require some continuous variable on x or y.
violation(bar_tick_area_line_without_continuous_x_y) :-
    attribute((mark,type),M,(bar;tick;area;line)),
    { helper(mark_channel_cont,M,x);helper(mark_channel_cont,M,y) } <= 0.

% @hard(no_stack_with_bar_area_discrete_color) Need to stack if we use bar, area with discrete color.
violation(no_stack_with_bar_area_discrete_color) :-
    helper(mark_channel_discrete_or_binned,M,color),
    attribute((mark,type),M,(bar;area)),
    not helper(mark_with_stack,M).

% @hard(stack_without_discrete_color_or_detail) Can only use stack if we also use discrete color, or detail.
violation(stack_without_discrete_color_or_detail) :-
    helper(mark_with_stack,M),
    not helper(mark_channel_discrete_or_binned,M,color),
    not helper((mark,channel),M,detail).

% @hard(stack_discrete) Stack can only be on continuous.
violation(stack_discrete) :-
    attribute((encoding,channel),E,C),
    attribute((encoding,stack),E,_),
    helper(mark_channel_discrete_or_binned,_,C).

% @soft(same_field) Prefer not to use the same field twice for the same mark.
preference(same_field,F) :-
    entity(field,_,F),
    entity(mark,_,M),
    { entity(encoding,M,E): helper((encoding,field),E,F) } = 2.

% @soft(same_field_grt3) Prefer not to use the same field three or more times for the same mark.
preference(same_field_grt3,F) :-
    entity(field,_,F),
    entity(mark,_,M),
    { entity(encoding,M,E): helper((encoding,field),E,F) } >= 3.

% @soft(number_categorical) Should not use categorical scale for number field.
preference(number_categorical,E) :-
    attribute((field,type),F,number),
    helper((encoding,field),E,F),
    helper((encoding,scale_type),E,categorical).

% @soft(only_discrete) Only discrete encoding channels are used in a mark.
preference(only_discrete,M) :-
    entity(mark,_,M),
    not helper(mark_encoding_cont,M,_).

% @soft(multi_non_pos) Prefer not to use multiple non-positional encoding channels.
preference(multi_non_pos,M) :-
    entity(mark,_,M),
    { helper((mark,channel),M,C): domain(non_positional,C) } > 1.

% @soft(non_pos_used_before_pos) Prefer not to use non-positional channels until all positional channels are used.
preference(non_pos_used_before_pos,M) :-
    helper((mark,channel),M,C),
    domain(non_positional,C),
    not helper((mark,channel),M,(x;y)).

% @soft(only_y) Prefer to use only x instead of only y.
preference(only_y,M) :-
    helper((mark,channel),M,y),
    not helper((mark,channel),M,x).

% @soft(high_cardinality_ordinal) Prefer not to use ordinal for fields with high cardinality.
preference(high_cardinality_ordinal,E) :-
    helper(encoding_cardinality,E,N),
    helper((encoding,scale_type),E,ordinal),
    N > 30.

% @soft(high_cardinality_categorical_grt10) Prefer not to use categorical (color) for fields with high cardinality.
preference(high_cardinality_categorical_grt10,E) :-
    helper(encoding_cardinality,E,N),
    helper((encoding,scale_type),E,categorical),
    N > 10.

% @soft(high_cardinality_shape) Prefer not to use high cardinality ordinal for shape.
preference(high_cardinality_shape,E) :-
    helper(encoding_cardinality,E,N),
    attribute((encoding,channel),E,shape),
    N > 8.

% @soft(high_cardinality_size) Prefer not to use size when the cardinality is large on x or y.
preference(high_cardinality_size,E) :-
    helper((mark,channel),M,size),
    entity(encoding,M,E),
    helper(encoding_cardinality,E,N),
    attribute((encoding,channel),E,(x;y)),
    not helper(mark_encoding_discrete_or_binned,M,E),
    N > 100.

% @soft(horizontal_scrolling_x) Avoid high cardinality on x as it causes horizontal scrolling.
preference(horizontal_scrolling_x,E) :-
    attribute((encoding,channel),E,x),
    helper(encoding_cardinality,E,N),
    helper(mark_encoding_discrete_or_binned,_,E),
    N > 50. 

% @soft(log_scale) log scale.
preference(log_scale,E) :-
    helper((encoding,scale_type),E,log).

% @soft(ordinal_scale) ordinal scale.
preference(ordinal_scale,E) :-
    helper((encoding,scale_type),E,ordinal).

% @soft(categorical_scale) categorical scale.
preference(categorical_scale,E) :-
    helper((encoding,scale_type),E,categorical).

% @soft(c_c_line) Continuous by continuous for line mark.
preference(c_c_line,M) :-
    helper(is_c_c,M),
    attribute((mark,type),M,line).

% @soft(c_c_area) Continuous by continuous for area mark.
preference(c_c_area,M) :-
    helper(is_c_c,M),
    attribute((mark,type),M,area).

% @soft(c_d_overlap_point) Continuous by discrete for point mark.
preference(c_d_overlap_point,M) :-
    helper(is_c_d,M),
    not helper(no_overlap,M),
    attribute((mark,type),M,point).

% @soft(c_d_overlap_bar) Continuous by discrete for bar mark.
preference(c_d_overlap_bar,M) :-
    helper(is_c_d,M),
    not helper(no_overlap,M),
    attribute((mark,type),M,bar).

% @soft(c_d_overlap_line) Continuous by discrete for line mark.
preference(c_d_overlap_line,M) :-
    helper(is_c_d,M),
    not helper(no_overlap,M),
    attribute((mark,type),M,line).

% @soft(c_d_overlap_area) Continuous by discrete for area mark.
preference(c_d_overlap_area,M) :-
    helper(is_c_d,M),
    not helper(no_overlap,M),
    attribute((mark,type),M,area).

% @soft(c_d_no_overlap_point) Continuous by discrete for point mark.
preference(c_d_no_overlap_point,M) :-
    helper(is_c_d,M),
    helper(no_overlap,M),
    attribute((mark,type),M,point).

% @soft(c_d_no_overlap_line) Continuous by discrete for line mark.
preference(c_d_no_overlap_line,M) :-
    helper(is_c_d,M),
    helper(no_overlap,M),
    attribute((mark,type),M,line).

% @soft(c_d_no_overlap_area) Continuous by discrete for area mark.
preference(c_d_no_overlap_area,M) :-
    helper(is_c_d,M),
    helper(no_overlap,M),
    attribute((mark,type),M,area).

% @soft(linear_color) Linear scale with color channel.
preference(linear_color,E) :-
    attribute((encoding,channel),E,color),
    helper((encoding,scale_type),E,linear).

% @soft(linear_size) Linear scale with size channel.
preference(linear_size,E) :-
    attribute((encoding,channel),E,size),
    helper((encoding,scale_type),E,linear).

% @soft(log_color) Log scale with color channel.
preference(log_color,E) :-
    attribute((encoding,channel),E,color),
    helper((encoding,scale_type),E,log).

% @soft(log_size) Log scale with size channel.
preference(log_size,E) :-
    attribute((encoding,channel),E,size),
    helper((encoding,scale_type),E,log).

% @soft(ordinal_x) Ordinal scale with x channel.
preference(ordinal_x,E) :-
    attribute((encoding,channel),E,x),
    helper((encoding,scale_type),E,ordinal).

% @soft(ordinal_color) Ordinal scale with color channel.
preference(ordinal_color,E) :-
    attribute((encoding,channel),E,color),
    helper((encoding,scale_type),E,ordinal).

% @soft(ordinal_size) Ordinal scale with size channel.
preference(ordinal_size,E) :-
    attribute((encoding,channel),E,size),
    helper((encoding,scale_type),E,ordinal).

% @soft(ordinal_shape) Ordinal scale with shape channel.
preference(ordinal_shape,E) :-
    attribute((encoding,channel),E,shape),
    helper((encoding,scale_type),E,ordinal).

% @soft(categorical_color) Categorical scale with color channel.
preference(categorical_color,E) :-
    attribute((encoding,channel),E,color),
    helper((encoding,scale_type),E,categorical).

% @soft(polar_coordinate) Polar coordinates.
preference(polar_coordinate,V) :-
    attribute((view,coordinates),V,polar).

% @soft(c_c_point) Continuous by continuous for point mark.
preference(c_c_point,M) :-
    helper(is_c_c,M),
    attribute((mark,type),M,point).

% @soft(c_d_overlap_tick) Continuous by discrete for tick mark.
preference(c_d_overlap_tick,M) :-
    helper(is_c_d,M),
    not helper(no_overlap,M),
    attribute((mark,type),M,tick).

% @soft(c_d_no_overlap_bar) Continuous by discrete for bar mark.
preference(c_d_no_overlap_bar,M) :-
    helper(is_c_d,M),
    helper(no_overlap,M),
    attribute((mark,type),M,bar).

% @soft(d_d_point) Discrete by discrete for point mark.
preference(d_d_point,M) :-
    helper(is_d_d,M),
    attribute((mark,type),M,point).

% @soft(d_d_rect) Discrete by discrete for rect mark.
preference(d_d_rect,M) :-
    helper(is_d_d,M),
    attribute((mark,type),M,rect).

% @soft(log_x) Log scale with x channel.
preference(log_x,E) :-
    attribute((encoding,channel),E,x),
    helper((encoding,scale_type),E,log).

% @soft(log_y) Log scale with y channel.
preference(log_y,E) :-
    attribute((encoding,channel),E,y),
    helper((encoding,scale_type),E,log).

% @soft(ordinal_y) Ordinal scale with y channel.
preference(ordinal_y,E) :-
    attribute((encoding,channel),E,y),
    helper((encoding,scale_type),E,ordinal).

