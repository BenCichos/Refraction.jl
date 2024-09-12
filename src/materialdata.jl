abstract type MaterialData end

abstract type Dispersion end
abstract type Constant <: Dispersion end
abstract type Formula <: Dispersion end
abstract type Table <: Dispersion end
