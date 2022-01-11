

mutable struct Balance
    # assets
    N :: Float64            # inventories
    K :: Float64            # capital
    NW :: Float64           # liquid assets

    # liabilities
    Deb :: Float64          # debt
    EQ :: Float64           # equity
end

mutable struct Machine
    A :: Float64                # labor productivity machine
    c :: Float64                # cost to produce machine
    freq :: Int16               # freq machine owned by cp
    age :: Float16              # age of machine
end