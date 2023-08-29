defmodule Wug.Thai.Sentencizer do
  @moduledoc "Given a pre-tokenized document, marks sentence boundaries."

  alias Wug.Document
  # alias Wug.Scanner

  @spec sentencize(Document.t()) :: Document.t()
  def sentencize(document) do
    document
  end
end
