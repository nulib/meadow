defmodule Authoritex.LOC.Genres do
  @desc "Library of Congress Genre/Form Terms"
  @moduledoc "Authoritex implementation for #{@desc}"

  use Authoritex.LOC.Base,
    subauthority: "authorities/genreForms",
    code: "lcgft",
    description: @desc
end

with authorities <-
       [Authoritex.LOC.Genres | Application.get_env(:authoritex, :authorities)]
       |> Enum.sort_by(&to_string/1) do
  Application.put_env(:authoritex, :authorities, authorities)
end
