const KAMA_PERIOD = 14
const FAST_EMA_CONSTANT_PERIOD = 2
const SLOW_EMA_CONSTANT_PERIOD = 30

"""
    KAMA{T}(; period = KAMA_PERIOD)

The KAMA type implements a Kaufman's Adaptive Moving Average indicator.
"""
mutable struct KAMA{Tval} <: OnlineStat{Tval}
    value::Union{Missing,Tval}
    n::Int

    period::Integer

    fast_smoothing_constant::Tval
    slow_smoothing_constant::Tval

    volatilities::CircBuff{Tval}

    input::CircBuff{Tval}

    function KAMA{Tval}(;
        period = KAMA_PERIOD,
        fast_ema_constant_period = FAST_EMA_CONSTANT_PERIOD,
        slow_ema_constant_period = SLOW_EMA_CONSTANT_PERIOD,
    ) where {Tval}
        @warn "WIP - buggy"

        fast_smoothing_constant = 2.0 / (fast_ema_constant_period + 1)
        slow_smoothing_constant = 2.0 / (slow_ema_constant_period + 1)

        volatilities = CircBuff(Tval, period, rev = false)

        input = CircBuff(Tval, period, rev = false)

        new{Tval}(
            missing,
            0,
            period,
            fast_smoothing_constant,
            slow_smoothing_constant,
            volatilities,
            input,
        )
    end
end

function OnlineStatsBase._fit!(ind::KAMA, data)
    fit!(ind.input, data)
    if ind.n != ind.period
        ind.n += 1
    end

    if ind.n >= 2
        fit!(ind.volatilities, abs(ind.input[end] - ind.input[end-1]))

        if length(ind.volatilities) < ind.period
            ind.value = missing
            return
        end

        volatility = sum(value(ind.volatilities))
        change = abs(ind.input[end] - ind.input[1])

        if volatility != 0
            efficiency_ratio = change / volatility
        else
            efficiency_ratio = 0
        end

        smoothing_constant =
            (
                efficiency_ratio *
                (ind.fast_smoothing_constant - ind.slow_smoothing_constant) +
                ind.slow_smoothing_constant
            )^2

        if !has_output_value(ind)  # tofix!!!!
            #if length(ind.value) == 0  # tofix!!!!
            prev_kama = ind.input[end-1]
        else
            prev_kama = ind.value[end]
        end

        ind.value = prev_kama + smoothing_constant * (ind.input[end] - prev_kama)
    end

end
