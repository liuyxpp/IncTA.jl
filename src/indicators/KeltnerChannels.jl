const KeltnerChannels_MA_PERIOD = 10
const KeltnerChannels_ATR_PERIOD = 10
const KeltnerChannels_ATR_MULT_UP = 2.0
const KeltnerChannels_ATR_MULT_DOWN = 3.0

struct KeltnerChannelsVal{Tval}
    lower::Tval
    central::Tval
    upper::Tval
end

"""
    KeltnerChannels{Tohlcv,S}(; ma_period = KeltnerChannels_MA_PERIOD, atr_period = KeltnerChannels_ATR_PERIOD, atr_mult_up = KeltnerChannels_ATR_MULT_UP, atr_mult_down = KeltnerChannels_ATR_MULT_DOWN)

The KeltnerChannels type implements a Keltner Channels indicator.
"""
mutable struct KeltnerChannels{Tohlcv,S} <: OnlineStat{Tohlcv}
    value::Union{Missing,KeltnerChannelsVal{S}}
    n::Int

    ma_period::Integer
    atr_period::Integer
    atr_mult_up::S
    atr_mult_down::S

    atr::ATR
    cb::EMA
    #cb::CallFun  # EMA candle.close

    function KeltnerChannels{Tohlcv,S}(;
        ma_period = KeltnerChannels_MA_PERIOD,
        atr_period = KeltnerChannels_ATR_PERIOD,
        atr_mult_up = KeltnerChannels_ATR_MULT_UP,
        atr_mult_down = KeltnerChannels_ATR_MULT_DOWN,
    ) where {Tohlcv,S}
        atr = ATR{Tohlcv,S}(period = atr_period)
        cb = EMA{S}(period = ma_period)
        # cb = ValueExtractor(EMA{S}(period=ma_period), candle -> candle.close)  # CallFun, ValueExtractor
        new{Tohlcv,S}(
            missing,
            0,
            ma_period,
            atr_period,
            atr_mult_up,
            atr_mult_down,
            atr,
            cb,
        )
    end
end

function OnlineStatsBase._fit!(ind::KeltnerChannels, candle::OHLCV)
    fit!(ind.atr, candle)
    fit!(ind.cb, candle.close)  # something like a ValueExtractor should be implemented
    ind.n += 1
    if has_output_value(ind.atr) && has_output_value(ind.cb)
        ind.value = KeltnerChannelsVal(
            value(ind.cb) - ind.atr_mult_down * value(ind.atr),
            value(ind.cb),
            value(ind.cb) + ind.atr_mult_up * value(ind.atr),
        )
    else
        ind.value = missing
    end
end
