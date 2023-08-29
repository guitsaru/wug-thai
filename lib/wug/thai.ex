defmodule Wug.Thai do
  @moduledoc "Configuration for Thai language parsing"

  alias Wug.Thai.Dictionary
  alias Wug.Thai.Tokenizer

  @behaviour Wug.Language

  @spec dictionary :: Dictionary.t()
  def dictionary, do: Dictionary.default()

  @spec sentencize(Wug.Document.t()) :: Wug.Document.t()
  def sentencize(document) do
    document
  end

  @spec tokenize(Wug.Document.t()) :: Wug.Document.t()
  def tokenize(document) do
    Tokenizer.tokenize(document, dictionary: dictionary())
  end
end
