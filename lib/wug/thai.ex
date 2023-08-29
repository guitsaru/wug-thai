defmodule Wug.Thai do
  @moduledoc "Configuration for Thai language parsing"

  alias Wug.Thai.Dictionary
  alias Wug.Thai.Tokenizer

  @behaviour Wug.Language

  @dictionary Dictionary.default()

  @spec dictionary :: Dictionary.t()
  def dictionary, do: @dictionary

  @spec sentencize(Wug.Document.t(), Keyword.t()) :: Wug.Document.t()
  def sentencize(document, _options \\ []) do
    document
  end

  @spec tokenize(Wug.Document.t(), Keyword.t()) :: Wug.Document.t()
  def tokenize(document, options \\ []) do
    dictionary = Keyword.get(options, :dictionary) || dictionary()
    opts = Keyword.put(options, :dictionary, dictionary)

    Tokenizer.tokenize(document, opts)
  end
end
