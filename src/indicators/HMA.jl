const HMA_PERIOD = 20

"""
    HMA{T}(; period = HMA_PERIOD)

The HMA type implements a Hull Moving Average indicator.
"""
mutable struct HMA{Tval} <: AbstractIncTAIndicator
    value::CircularBuffer{Union{Missing,Tval}}

    period::Integer

    wma::WMA{Tval}
    wma2::WMA{Tval}
    hma::WMA{Tval}

    function HMA{Tval}(; period = HMA_PERIOD) where {Tval}

        value = CircularBuffer{Union{Missing,Tval}}(period)

        wma = WMA{Tval}(period = period)
        wma2 = WMA{Tval}(period = floor(Int, period / 2))
        hma = WMA{Tval}(period = floor(Int, sqrt(period)))

        new{Tval}(value, period, wma, wma2, hma)
    end
end


function Base.push!(ind::HMA{Tval}, val::Tval) where {Tval}
    push!(ind.wma, val)
    push!(ind.wma2, val)

    if !has_output_value(ind.wma)
        out_val = missing
    else
        push!(ind.hma, 2.0 * ind.wma2.value[end] - ind.wma.value[end])

        if !has_output_value(ind.hma)
            out_val = missing
        else
            out_val = ind.hma.value[end]
        end
    end

    push!(ind.value, out_val)
    return out_val
end
