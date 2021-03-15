defmodule Meadow.TestSupport.MetadataGenerator do
  @moduledoc """
  Generate random descriptive metadata for works
  """

  alias Meadow.Data.ControlledTerms
  alias Meadow.Data.Works

  @values %{
    contributor: [
      %{
        id: "http://id.loc.gov/authorities/names/no2011087251",
        label: "Valim, Jose"
      },
      %{
        id: "http://id.loc.gov/authorities/names/n85153068",
        label: "Mandela, Nelson, 1918-2013"
      },
      %{
        id: "http://id.loc.gov/authorities/names/n79091588",
        label: "Dewey, Melvil, 1851-1931"
      },
      %{
        id: "http://id.loc.gov/authorities/names/n83175996",
        label: "Hopper, Grace Murray"
      },
      %{
        id: "http://id.loc.gov/authorities/names/n78030997",
        label: "Lovelace, Ada King, Countess of, 1815-1852"
      },
      %{
        id: "http://id.loc.gov/authorities/names/n50053919",
        label: "Ranganathan, S. R. (Shiyali Ramamrita), 1892-1972"
      }
    ],
    creator: [
      %{id: "http://vocab.getty.edu/ulan/500030701", label: "Kahlo, Frida"},
      %{id: "http://vocab.getty.edu/ulan/500029268", label: "Pei, I. M."},
      %{id: "http://vocab.getty.edu/ulan/500018219", label: "Curtis, Edward S."},
      %{id: "http://vocab.getty.edu/ulan/500115207", label: "Muybridge, Eadweard"},
      %{id: "http://vocab.getty.edu/ulan/500102192", label: "Claudel, Camille"},
      %{
        id: "http://vocab.getty.edu/ulan/500445403",
        label: "Aberdare, Henry Bruce, 2nd Baron"
      }
    ],
    genre: [
      %{id: "http://vocab.getty.edu/aat/300386217", label: "genre artists"},
      %{id: "http://vocab.getty.edu/aat/300139140", label: "genre pictures"},
      %{id: "http://vocab.getty.edu/aat/300266117", label: "genre painters"},
      %{id: "http://vocab.getty.edu/aat/300056462", label: "art genres"},
      %{
        id: "http://vocab.getty.edu/aat/300185712",
        label: "object genres (object classifications)"
      },
      %{id: "http://vocab.getty.edu/aat/300026031", label: "document genres"}
    ],
    language: [
      %{id: "http://id.loc.gov/vocabulary/languages/cha", label: "Chamorro"},
      %{id: "http://id.loc.gov/vocabulary/languages/div", label: "Divehi"},
      %{id: "http://id.loc.gov/vocabulary/languages/lin", label: "Lingala"},
      %{id: "http://id.loc.gov/vocabulary/languages/bug", label: "Bugis"},
      %{id: "http://id.loc.gov/vocabulary/languages/nia", label: "Nias"},
      %{id: "http://id.loc.gov/vocabulary/languages/kor", label: "Korean"}
    ],
    location: [
      %{id: "https://sws.geonames.org/3598132/", label: "Guatemala City"},
      %{id: "https://sws.geonames.org/3530597/", label: "Mexico City"},
      %{id: "https://sws.geonames.org/3703443/", label: "Panama City"},
      %{id: "https://sws.geonames.org/3582677/", label: "Belize City"},
      %{id: "https://sws.geonames.org/2347283/", label: "Benin City"},
      %{id: "https://sws.geonames.org/292932/", label: "Ajman"},
      %{id: "http://vocab.getty.edu/tgn/7549617", label: "Coco Channel"},
      %{id: "http://vocab.getty.edu/tgn/1114106", label: "Coco Channel"},
      %{
        id: "https://sws.geonames.org/4921868/",
        label: "Indiana"
      },
      %{
        id: "http://id.worldcat.org/fast/1204604",
        label: "Indiana"
      },
      %{
        id: "http://id.loc.gov/authorities/names/n79022925",
        label: "Indiana"
      }
    ],
    style_period: [
      %{id: "http://vocab.getty.edu/aat/300312140", label: "White Style"},
      %{id: "http://vocab.getty.edu/aat/300375728", label: "Glasgow style"},
      %{id: "http://vocab.getty.edu/aat/300378903", label: "Style Guimard"},
      %{id: "http://vocab.getty.edu/aat/300375737", label: "Yachting Style"},
      %{
        id: "http://vocab.getty.edu/aat/300375743",
        label: "Modern Style (Art Nouveau )"
      },
      %{id: "http://vocab.getty.edu/aat/300378910", label: "Quaint Style"}
    ],
    subject: [
      %{
        id: "http://id.loc.gov/authorities/subjects/sh2002006395",
        label: "Library"
      },
      %{
        id: "http://id.loc.gov/authorities/subjects/sh85070610",
        label: "John Cotton Dana Library Public Relations Award"
      },
      %{
        id: "http://id.loc.gov/authorities/subjects/sh85076710",
        label: "Library pages"
      },
      %{
        id: "http://id.loc.gov/authorities/subjects/sh85076671",
        label: "Library catalogs and users"
      }
    ],
    technique: [
      %{id: "http://vocab.getty.edu/aat/300265034", label: "Six's Technique"},
      %{id: "http://vocab.getty.edu/aat/300400619", label: "Levallois technique"},
      %{
        id: "http://vocab.getty.edu/aat/300435429",
        label: "materials/technique description"
      },
      %{id: "http://vocab.getty.edu/aat/300053376", label: "soak-stain technique"},
      %{
        id: "http://vocab.getty.edu/aat/300438611",
        label: "micro hot table technique"
      },
      %{id: "http://vocab.getty.edu/aat/300410254", label: "sarga (technique)"}
    ]
  }

  @roles %{
    "marc_relator" => ~w(aut lil mrb pbl stl vac),
    "subject_role" => ~w(GEOGRAPHICAL TOPICAL)
  }

  def prewarm_cache do
    Enum.each(@values, fn {_field, value} ->
      Enum.each(value, fn term -> ControlledTerms.cache!(term) end)
    end)
  end

  @spec generate_descriptive_metadata_for(
          maybe_improper_list(
            maybe_improper_list(maybe_improper_list(any, [] | map) | map, [] | map)
            | Meadow.Data.Schemas.Work.t(),
            [] | Meadow.Data.Schemas.Work.t()
          )
          | Meadow.Data.Schemas.Work.t()
        ) :: any
  def generate_descriptive_metadata_for([]), do: []

  def generate_descriptive_metadata_for([work | works]) do
    [generate_descriptive_metadata_for(work) | generate_descriptive_metadata_for(works)]
  end

  def generate_descriptive_metadata_for(work) do
    work |> Works.update_work(%{descriptive_metadata: random_descriptive_metadata()})
  end

  def random_descriptive_metadata do
    %{
      title: Faker.Lorem.sentence(),
      contributor: random_number_of(:contributor),
      creator: random_number_of(:creator),
      genre: random_number_of(:genre),
      language: random_number_of(:language),
      location: random_number_of(:location),
      style_period: random_number_of(:style_period),
      subject: random_number_of(:subject),
      technique: random_number_of(:technique)
    }
  end

  defp random_number_of(field) do
    min = if field == :creator, do: 1, else: 0

    with pool <- @values[field] do
      0..Enum.random(min..5)
      |> Enum.map(fn _ ->
        with value <- Enum.random(pool) do
          case field do
            :contributor -> %{role: random_role("marc_relator"), term: %{id: value.id}}
            :subject -> %{role: random_role("subject_role"), term: %{id: value.id}}
            _ -> %{role: nil, term: %{id: value.id}}
          end
        end
      end)
    end
    |> Enum.uniq()
  end

  defp random_role(scheme) do
    with id <- @roles |> Map.get(scheme) |> Enum.random() do
      %{id: id, scheme: scheme}
    end
  end
end
