defmodule Wug.Scanner do
  @moduledoc "Implements a scanner for Wug documents."

  alias Wug.Array
  alias Wug.Document

  @type t :: %__MODULE__{data: Array.t(), pointer: non_neg_integer()}
  @typep maybe_token :: Token.t() | nil

  defstruct data: Array.new(), pointer: 0

  @spec new(Document.t()) :: t()
  def new(document) do
    %__MODULE__{data: Array.new(document.tokens), pointer: 0}
  end

  @spec current(t()) :: maybe_token
  def current(scanner), do: Array.get(scanner.data, scanner.pointer)

  @spec next(t()) :: maybe_token
  def next(scanner) do
    scanner = %{scanner | pointer: scanner.pointer + 1}
    current(scanner)
  end

  @spec previous(t()) :: maybe_token
  def previous(scanner) do
    scanner = %{scanner | pointer: scanner.pointer - 1}
    current(scanner)
  end

  @spec peek(t(), integer()) :: maybe_token
  def peek(scanner, count \\ 1), do: Array.get(scanner.data, scanner.pointer + count)
end
