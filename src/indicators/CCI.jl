const CCI_PERIOD = 3

"""
    CCI{Tohlcv,S}(; period=CCI_PERIOD, input_filter = always_true, input_modifier = identity, input_modifier_return_type = Tohlcv)

The `CCI` type implements a Commodity Channel Index.
"""
mutable struct CCI{Tohlcv,S} <: TechnicalIndicator{Tohlcv}
    value::Union{Missing,S}
    n::Int
    output_listeners::Series
    input_indicator::Union{Missing,TechnicalIndicator}

    period::Integer

    mean_dev::MeanDev

    input_modifier::Function
    input_filter::Function

    function CCI{Tohlcv,S}(;
        period = CCI_PERIOD,
        input_filter = always_true,
        input_modifier = identity,
        input_modifier_return_type = Tohlcv,  # not necessary but here to unify interface
    ) where {Tohlcv,S}
        mean_dev = MeanDev{S}(period = period)
        new{Tohlcv,S}(
            initialize_indicator_common_fields()...,
            period,
            mean_dev,
            input_modifier,
            input_filter,
        )
    end
end

function _calculate_new_value_only_from_incoming_data(ind::CCI, candle)
    typical_price = (candle.high + candle.low + candle.close) / 3.0
    fit!(ind.mean_dev, typical_price)
    return has_output_value(ind.mean_dev) ?
           (typical_price - value(ind.mean_dev.ma)) / (0.015 * value(ind.mean_dev)) :
           missing
end
