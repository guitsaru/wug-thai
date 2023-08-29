defmodule Wug.Scanner do
  @moduledoc "Implements a text scanner"

  alias Wug.Array

  @type t :: %__MODULE__{data: Array.t(), pointer: integer()}
  @typep maybe_item :: any | nil

  defstruct data: Array.new(), pointer: -1

  @spec new(list()) :: t()
  def new(list) do
    %__MODULE__{data: Array.new(list), pointer: -1}
  end

  @spec current(t()) :: maybe_item
  def current(scanner), do: Array.get(scanner.data, scanner.pointer)

  @spec next(t()) :: {maybe_item, t()}
  def next(scanner) do
    scanner = %{scanner | pointer: scanner.pointer + 1}
    {current(scanner), scanner}
  end

  @spec previous(t()) :: {maybe_item, t()}
  def previous(scanner) do
    scanner = %{scanner | pointer: scanner.pointer - 1}
    {current(scanner), scanner}
  end

  @spec peek(t(), integer()) :: maybe_item
  def peek(scanner, count \\ 1), do: Array.get(scanner.data, scanner.pointer + count)

  @spec set_pointer(t(), non_neg_integer()) :: t()
  def set_pointer(scanner, pointer) do
    %{scanner | pointer: pointer}
  end

  @spec is_end?(t()) :: boolean()
  def is_end?(scanner) do
    scanner.pointer >= scanner.data.length
  end

  @spec slice(t(), non_neg_integer(), pos_integer()) :: List.t()
  def slice(scanner, start, length) do
    Array.slice(scanner.data, start, length)
  end
end
