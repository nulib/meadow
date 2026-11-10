defmodule Meadow.Embeddings.TextTest do
  use ExUnit.Case, async: true

  alias Meadow.Embeddings.Text

  @document %{
    title: "Jazz Festival Poster",
    alternate_title: ["Festival de jazz", "Jazzfest"],
    description: [],
    collection: %{id: "abc", title: "Posters"},
    creator: [%{label: "Doe, Jane", id: "nope"}],
    contributor: [%{label: "Smith, John", label_with_role: "Smith, John (Printer)"}],
    subject: [%{label: "Jazz"}, %{label: "Festivals"}],
    date_created: nil,
    visibility: "Public",
    accession_number: "P-001"
  }

  describe "build/1" do
    test "labels each configured field, in configured order" do
      assert Text.build(@document).text ==
               """
               title: Jazz Festival Poster
               alternate_title: Festival de jazz; Jazzfest
               collection: Posters
               creator: Doe, Jane
               contributor: Smith, John (Printer)
               subject: Jazz; Festivals
               accession_number: P-001\
               """
    end

    test "leaves out empty fields and fields that are not configured" do
      text = Text.build(@document).text
      refute text =~ "description"
      refute text =~ "date_created"
      refute text =~ "visibility"
    end

    test "wraps the text in the document prompt, with the work's title" do
      %{prompt: prompt, text: text} = Text.build(@document)
      assert prompt == "title: Jazz Festival Poster | text: " <> text
    end

    test "uses the untitled document prompt when there is no title" do
      assert %{title: nil, prompt: "title: none | text: subject: Jazz"} =
               Text.build(%{subject: [%{label: "Jazz"}]})
    end

    test "hashes the prompt" do
      text = Text.build(@document)
      assert text.hash == Text.hash(text.prompt)
      assert text.hash =~ ~r/^[0-9a-f]{64}$/
      assert Text.build(%{@document | title: "Other"}).hash != text.hash
      assert Text.build(%{@document | visibility: "Private"}).hash == text.hash
    end

    test "truncates long text but reports the full length" do
      text = Text.build(%{@document | title: String.duplicate("é", 5000)})
      assert text.length > 5000
      assert byte_size(text.text) <= 2048
      assert String.valid?(text.text)
    end
  end

  describe "truncate/2" do
    test "never splits a multibyte character" do
      assert Text.truncate("ééé", 3) == "é"
      assert Text.truncate("abc", 10) == "abc"
    end
  end
end
