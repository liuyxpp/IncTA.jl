const ChaikinOsc_FAST_PERIOD = 5
const ChaikinOsc_SLOW_PERIOD = 7

"""
    ChaikinOsc{Tohlcv,S}(; fast_period = ChaikinOsc_FAST_PERIOD, slow_period = ChaikinOsc_SLOW_PERIOD, fast_ma = EMA, slow_ma = EMA)

The ChaikinOsc type implements a Chaikin Oscillator.
"""
mutable struct ChaikinOsc{Tohlcv,S} <: TechnicalIndicator{Tohlcv}
    value::Union{Missing,S}
    n::Int

    sub_indicators::Series
    # accu_dist::AccuDist{Tohlcv}

    fast_ma::Any  # EMA by default
    slow_ma::Any  # EMA by default

    function ChaikinOsc{Tohlcv,S}(;
        fast_period = ChaikinOsc_FAST_PERIOD,
        slow_period = ChaikinOsc_SLOW_PERIOD,
        fast_ma = EMA,
        slow_ma = EMA,
    ) where {Tohlcv,S}
        accu_dist = AccuDist{Tohlcv,S}()
        sub_indicators = Series(accu_dist)
        _fast_ma = MAFactory(S)(fast_ma, fast_period)
        _slow_ma = MAFactory(S)(slow_ma, slow_period)
        new{Tohlcv,S}(missing, 0, sub_indicators, _fast_ma, _slow_ma)
    end
end

function OnlineStatsBase._fit!(ind::ChaikinOsc, candle)
    fit!(ind.sub_indicators, candle)
    accu_dist, = ind.sub_indicators.stats
    ind.n += 1
    if has_output_value(accu_dist)
        accu_dist_value = value(accu_dist)
        fit!(ind.fast_ma, accu_dist_value)
        fit!(ind.slow_ma, accu_dist_value)
        if has_output_value(ind.fast_ma) && has_output_value(ind.slow_ma)
            ind.value = value(ind.fast_ma) - value(ind.slow_ma)
        else
            ind.value = missing
        end
    else
        ind.value = missing
    end
end
