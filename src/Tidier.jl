module Tidier

using DataFrames
using MacroTools
using Chain
using Statistics
using Reexport

@reexport using Chain
@reexport using Statistics

export Tidier_set, across, desc, starts_with, ends_with, matches, @select, @transmute, @rename, @mutate, @summarize, @summarise, @filter, @group_by, @slice, @arrange

include("docstrings.jl")
include("parsing.jl")

# Package global variables
const code = Ref{Bool}(false) # output DataFrames.jl code?
const log = Ref{Bool}(false) # output tidylog output? (not yet implemented)

# Functions to set global variables
"""
$docstring_Tidier_set
"""
function Tidier_set(option::AbstractString, value::Bool)
  if option == "code"
    code[] = value
  elseif option == "log"
    throw("Logging is not enabled yet")
  else
    throw("That is not a valid option.")
  end
end

# Need to expand with docs
# These are just aliases
starts_with(args...) = startswith(args...)
ends_with(args...) = endswith(args...)
matches(pattern, flags...) = Regex(pattern, flags...)

"""
$docstring_across
"""
function across(args...)
  throw("This function should only be called inside of @mutate(), @summarize, or @summarise.")
end

"""
$docstring_desc
"""
function desc(args...)
  throw("This function should only be called inside of @arrange().")
end

"""
$docstring_select
"""
macro select(df, exprs...)
  tidy_exprs = parse_interpolation.(exprs)
  tidy_exprs = parse_tidy.(tidy_exprs)
  df_expr = quote
    select($(esc(df)), $(tidy_exprs...))
  end
  if code[]
    @info MacroTools.prettify(df_expr)
  end
  return df_expr
end

"""
$docstring_transmute
"""
macro transmute(df, exprs...)
  tidy_exprs = parse_interpolation.(exprs)
  tidy_exprs = parse_tidy.(tidy_exprs)
  df_expr = quote
    select($(esc(df)), $(tidy_exprs...))
  end
  if code[]
    @info MacroTools.prettify(df_expr)
  end
  return df_expr
end

"""
$docstring_rename
"""
macro rename(df, exprs...)
  tidy_exprs = parse_interpolation.(exprs)
  tidy_exprs = parse_tidy.(tidy_exprs)
  df_expr = quote
    rename($(esc(df)), $(tidy_exprs...))
  end
  if code[]
    @info MacroTools.prettify(df_expr)
  end
  return df_expr
end

"""
$docstring_mutate
"""
macro mutate(df, exprs...)
  tidy_exprs = parse_interpolation.(exprs)
  tidy_exprs = parse_tidy.(tidy_exprs)
  df_expr = quote
    transform($(esc(df)), $(tidy_exprs...))
  end
  if code[]
    @info MacroTools.prettify(df_expr)
  end
  return df_expr
end

"""
$docstring_summarize
"""
macro summarize(df, exprs...)
  tidy_exprs = parse_interpolation.(exprs)
  tidy_exprs = parse_tidy.(tidy_exprs; autovec=false)
  df_expr = quote
    combine($(esc(df)), $(tidy_exprs...))
  end
  if code[]
    @info MacroTools.prettify(df_expr)
  end
  return df_expr
end

"""
$docstring_summarize
"""
macro summarise(df, exprs...)
  tidy_exprs = parse_interpolation.(exprs)
  tidy_exprs = parse_tidy.(tidy_exprs; autovec=false)
  df_expr = quote
    combine($(esc(df)), $(tidy_exprs...))
  end
  if code[]
    @info MacroTools.prettify(df_expr)
  end
  return df_expr
end

"""
$docstring_filter
"""
macro filter(df, exprs...)
  tidy_exprs = parse_interpolation.(exprs)
  tidy_exprs = parse_tidy.(tidy_exprs; subset=true)
  df_expr = quote
    subset($(esc(df)), $(tidy_exprs...))
  end
  if code[]
    @info MacroTools.prettify(df_expr)
  end
  return df_expr
end

"""
$docstring_group_by
"""
macro group_by(df, exprs...)
  # Group
  tidy_exprs = parse_interpolation.(exprs)
  tidy_exprs = parse_tidy.(tidy_exprs)
  grouping_exprs = parse_group_by.(exprs)

  df_expr = quote
    groupby(transform($(esc(df)), $(tidy_exprs...)), Cols($(grouping_exprs...)))
  end
  if code[]
    @info MacroTools.prettify(df_expr)
  end
  return df_expr
end

"""
$docstring_slice
"""
macro slice(df, exprs...)
  original_indices = [eval.(exprs)...]
  clean_indices = Int64[]
  for index in original_indices
    if index isa Number
      push!(clean_indices, index)
    else
      append!(clean_indices, collect(index))
    end
  end
  clean_indices = unique(clean_indices)

  if all(clean_indices .> 0)
    df_expr = quote
      select(subset(transform($(esc(df)), eachindex => :Tidier_row_number),
          :Tidier_row_number => x -> (in.(x, Ref($clean_indices)))),
        Not(:Tidier_row_number))
    end
  elseif all(clean_indices .< 0)
    clean_indices = -clean_indices
    df_expr = quote
      select(subset(transform($(esc(df)), eachindex => :Tidier_row_number),
          :Tidier_row_number => x -> (.!in.(x, Ref($clean_indices)))),
        Not(:Tidier_row_number))
    end
  else
    throw("@slice() indices must either be all positive or all negative.")
  end

  if code[]
    @info MacroTools.prettify(df_expr)
  end
  return df_expr
end

"""
$docstring_arrange
"""
macro arrange(df, exprs...)
  arrange_exprs = parse_desc.(exprs)
  df_expr = quote
    sort($(esc(df)), [$(arrange_exprs...)]) # Must use [] instead of Cols() here
  end
  if code[]
    @info MacroTools.prettify(df_expr)
  end
  return df_expr
end

end