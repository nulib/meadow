PUT _scripts/meadow-v1-ControlledTerm
{
  "script": {
    "lang": "painless",
    "source": """
    def field = params.field;
    
    ctx.descriptiveMetadata[field] = ctx.descriptiveMetadata[field].stream().map(entry -> {
        def facetRole = "";
        entry.displayFacet = entry.term.label;
        if (entry.role != null) {
          facetRole = entry.role.id;
        }
        entry.facet = [entry.term.id, facetRole, entry.term.label].join("|");
        return entry;
      })
      .collect(Collectors.toList());
    """
  }
}

PUT _ingest/pipeline/meadow-v1-WorkAdministrativeMetadata
{
  "description": "Meadow V1 Work Administrative Metadata Pipeline",
  "processors": [
    {
      "rename": {
        "field": "original.administrative_metadata.library_unit",
        "target_field": "administrativeMetadata.libraryUnit"
      }
    },
    {
      "rename": {
        "field": "original.administrative_metadata.preservation_level",
        "target_field": "administrativeMetadata.preservationLevel"
      }
    },
    {
      "rename": {
        "field": "original.administrative_metadata.project_cycle",
        "target_field": "administrativeMetadata.projectCycle"
      }
    },
    {
      "rename": {
        "field": "original.administrative_metadata.project_desc",
        "target_field": "administrativeMetadata.projectDesc"
      }
    },
    {
      "rename": {
        "field": "original.administrative_metadata.project_manager",
        "target_field": "administrativeMetadata.projectManager"
      }
    },
    {
      "rename": {
        "field": "original.administrative_metadata.project_name",
        "target_field": "administrativeMetadata.projectName"
      }
    },
    {
      "rename": {
        "field": "original.administrative_metadata.project_proposer",
        "target_field": "administrativeMetadata.projectProposer"
      }
    },
    {
      "rename": {
        "field": "original.administrative_metadata.project_task_number",
        "target_field": "administrativeMetadata.projectTaskNumber"
      }
    },
    {
      "rename": {
        "field": "original.administrative_metadata.status",
        "target_field": "administrativeMetadata.status"
      }
    }
  ]
}

PUT _ingest/pipeline/meadow-v1-WorkDescriptiveMetadata
{
  "description": "Meadow V1 Work Descriptive Metadata Pipeline",
  "processors": [
    {
      "rename": {
        "field": "original.descriptive_metadata.abstract",
        "target_field": "descriptiveMetadata.abstract"
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.alternate_title",
        "target_field": "descriptiveMetadata.alternateTitle"
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.ark",
        "target_field": "descriptiveMetadata.ark"
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.box_name",
        "target_field": "descriptiveMetadata.boxName"
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.box_number",
        "target_field": "descriptiveMetadata.boxNumber"
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.caption",
        "target_field": "descriptiveMetadata.caption"
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.catalog_key",
        "target_field": "descriptiveMetadata.catalogKey"
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.citation",
        "target_field": "descriptiveMetadata.citation"
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.contributor",
        "target_field": "descriptiveMetadata.contributor"
      }
    },
    {
      "script": {
        "id": "meadow-v1-ControlledTerm",
        "params": {
          "field": "contributor"
        }
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.creator",
        "target_field": "descriptiveMetadata.creator"
      }
    },
    {
      "script": {
        "id": "meadow-v1-ControlledTerm",
        "params": {
          "field": "creator"
        }
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.cultural_context",
        "target_field": "descriptiveMetadata.culturalContext"
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.date_created",
        "target_field": "descriptiveMetadata.dateCreated"
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.description",
        "target_field": "descriptiveMetadata.description"
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.folder_name",
        "target_field": "descriptiveMetadata.folderName"
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.folder_number",
        "target_field": "descriptiveMetadata.folderNumber"
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.genre",
        "target_field": "descriptiveMetadata.genre"
      }
    },
    {
      "script": {
        "id": "meadow-v1-ControlledTerm",
        "params": {
          "field": "genre"
        }
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.identifier",
        "target_field": "descriptiveMetadata.identifier"
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.keywords",
        "target_field": "descriptiveMetadata.keywords"
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.language",
        "target_field": "descriptiveMetadata.language"
      }
    },
    {
      "script": {
        "id": "meadow-v1-ControlledTerm",
        "params": {
          "field": "language"
        }
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.legacy_identifier",
        "target_field": "descriptiveMetadata.legacyIdentifier"
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.license.id",
        "target_field": "descriptiveMetadata.license.id",
        "on_failure": [
          {
            "set": {
              "field": "descriptiveMetadata.license",
              "value": {}
            }
          }
        ]
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.license.label",
        "target_field": "descriptiveMetadata.license.label",
        "ignore_missing": true
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.license.scheme",
        "target_field": "descriptiveMetadata.license.scheme",
        "ignore_missing": true
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.location",
        "target_field": "descriptiveMetadata.location"
      }
    },
    {
      "script": {
        "id": "meadow-v1-ControlledTerm",
        "params": {
          "field": "location"
        }
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.notes",
        "target_field": "descriptiveMetadata.notes"
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.physical_description_material",
        "target_field": "descriptiveMetadata.physicalDescriptionMaterial"
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.physical_description_size",
        "target_field": "descriptiveMetadata.physicalDescriptionSize"
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.provenance",
        "target_field": "descriptiveMetadata.provenance"
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.publisher",
        "target_field": "descriptiveMetadata.publisher"
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.related_material",
        "target_field": "descriptiveMetadata.relatedMaterial"
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.related_url",
        "target_field": "descriptiveMetadata.relatedUrl"
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.rights_holder",
        "target_field": "descriptiveMetadata.rightsHolder"
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.rights_statement.id",
        "target_field": "descriptiveMetadata.rightsStatement.id",
        "on_failure": [
          {
            "set": {
              "field": "descriptiveMetadata.rightsStatement",
              "value": {}
            }
          }
        ]
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.rights_statement.label",
        "target_field": "descriptiveMetadata.rightsStatement.label",
        "ignore_missing": true
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.rights_statement.scheme",
        "target_field": "descriptiveMetadata.rightsStatement.scheme",
        "ignore_missing": true
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.scope_and_contents",
        "target_field": "descriptiveMetadata.scopeAndContents"
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.series",
        "target_field": "descriptiveMetadata.series"
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.source",
        "target_field": "descriptiveMetadata.source"
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.style_period",
        "target_field": "descriptiveMetadata.stylePeriod"
      }
    },
    {
      "script": {
        "id": "meadow-v1-ControlledTerm",
        "params": {
          "field": "stylePeriod"
        }
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.subject",
        "target_field": "descriptiveMetadata.subject"
      }
    },
    {
      "script": {
        "id": "meadow-v1-ControlledTerm",
        "params": {
          "field": "subject"
        }
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.table_of_contents",
        "target_field": "descriptiveMetadata.tableOfContents"
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.technique",
        "target_field": "descriptiveMetadata.technique"
      }
    },
    {
      "script": {
        "id": "meadow-v1-ControlledTerm",
        "params": {
          "field": "technique"
        }
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.terms_of_use",
        "target_field": "descriptiveMetadata.termsOfUse"
      }
    },
    {
      "rename": {
        "field": "original.descriptive_metadata.title",
        "target_field": "descriptiveMetadata.title"
      }
    }
  ]
}

PUT _ingest/pipeline/meadow-v1-Work
{
  "description": "Meadow V1 Work Pipeline",
  "processors": [
    {
      "rename": {
        "field": "original.accession_number",
        "target_field": "accessionNumber"
      }
    },
    {
      "foreach": {
        "field": "original.batches",
        "processor": {
          "append": {
            "field": "batches",
            "value": "{{{_ingest._value.id}}}"
          }
        }
      }
    },
    {
      "rename": {
        "field": "original.collection.id",
        "target_field": "collection.id",
        "on_failure": [
          {
            "set": {
              "field": "collection",
              "value": {}
            }
          }
        ]
      }
    },
    {
      "rename": {
        "field": "original.collection.title",
        "target_field": "collection.title",
        "ignore_missing": true
      }
    },
    {
      "rename": {
        "field": "original.inserted_at",
        "target_field": "createDate"
      }
    },
    {
      "foreach": {
        "field": "original.metadata_update_jobs",
        "processor": {
          "append": {
            "field": "metadataUpdateJobs",
            "value": "{{{_ingest._value.id}}}"
          }
        }
      }
    },
    {
      "rename": {
        "field": "original.id",
        "target_field": "id"
      }
    },
    {
      "rename": {
        "field": "original.iiif_manifest",
        "target_field": "iiifManifest",
        "ignore_missing": true
      }
    },
    {
      "set": {
        "field": "model.application",
        "value": "Meadow"
      }
    },
    {
      "set": {
        "field": "model.name",
        "value": "Work"
      }
    },
    {
      "rename": {
        "field": "original.updated_at",
        "target_field": "modifiedDate"
      }
    },
    {
      "rename": {
        "field": "original.project.id",
        "target_field": "project.id",
        "on_failure": [
          {
            "set": {
              "field": "project",
              "value": {}
            }
          }
        ]
      }
    },
    {
      "rename": {
        "field": "original.project.title",
        "target_field": "project.title",
        "ignore_missing": true
      }
    },
    {
      "rename": {
        "field": "original.published",
        "target_field": "published"
      }
    },
    {
      "rename": {
        "field": "original.representative_file_set_id",
        "target_field": "representativeFileSet.fileSetId"
      }
    },
    {
      "rename": {
        "field": "original.representative_image",
        "target_field": "representativeFileSet.url"
      }
    },
    {
      "rename": {
        "field": "original.ingest_sheet.id",
        "target_field": "sheet.id",
        "on_failure": [
          {
            "set": {
              "field": "sheet",
              "value": {}
            }
          }
        ]
      }
    },
    {
      "rename": {
        "field": "original.ingest_sheet.title",
        "target_field": "sheet.title",
        "ignore_missing": true
      }
    },
    {
      "rename": {
        "field": "original.thumbnail",
        "target_field": "thumbnail",
        "ignore_missing": true
      }
    },
    {
      "rename": {
        "field": "original.visibility.id",
        "target_field": "visibility.id"
      }
    },
    {
      "rename": {
        "field": "original.visibility.label",
        "target_field": "visibility.label"
      }
    },
    {
      "rename": {
        "field": "original.work_type.id",
        "target_field": "workType.id"
      }
    },
    {
      "rename": {
        "field": "original.work_type.label",
        "target_field": "workType.label"
      }
    },
    {
      "pipeline": {
        "name": "meadow-v1-WorkAdministrativeMetadata"
      }
    },
    {
      "pipeline": {
        "name": "meadow-v1-WorkDescriptiveMetadata"
      }
    },
    {
      "remove": {
        "field": "original"
      }
    },
    {
      "set": {
        "field": "title",
        "value": "{{descriptiveMetadata.title}}"
      }
    },
    {
      "set": {
        "field": "alternateTitle",
        "value": []
      }
    },
    {
      "foreach": {
        "field": "descriptiveMetadata.alternateTitle",
        "processor": {
          "append": {
            "field": "alternateTitle",
            "value": ["{{_ingest._value}}"]
          }
        }
      }
    },
    {
      "set": {
        "field": "description",
        "value": []
      }
    },
    {
      "foreach": {
        "field": "descriptiveMetadata.description",
        "processor": {
          "append": {
            "field": "description",
            "value": ["{{_ingest._value}}"]
          }
        }
      }
    },
    {
      "foreach": {
        "field": "descriptiveMetadata.creator",
        "processor": {
          "append": {
            "field": "creator",
            "value": "{{_ingest._value.term.label}}"
          }
        }
      }
    },
    {
      "foreach": {
        "field": "descriptiveMetadata.contributor",
        "processor": {
          "append": {
            "field": "contributor",
            "value": "{{_ingest._value.term.label}}"
          }
        }
      }
    },
    {
      "foreach": {
        "field": "descriptiveMetadata.dateCreated",
        "processor": {
          "append": {
            "field": "dateCreated",
            "value": "{{_ingest._value.humanized}}"
          }
        }
      }
    },
    {
      "foreach": {
        "field": "descriptiveMetadata.subject",
        "processor": {
          "append": {
            "field": "subject",
            "value": "{{_ingest._value.term.label}}"
          }
        }
      }
    },
    {
      "set": {
        "field": "collectionTitle",
        "value": "{{collection.title}}",
        "on_failure": [
          {
            "set": {
              "field": "collectionTitle",
              "value": ""
            }
          }
        ]
      }
    }
  ]
}

GET /mbk-dev-meadow-with-pipeline/_doc/156a8f8e-549b-4982-86cc-375bf04104ff

POST /mbk-dev-meadow-with-pipeline/_doc/156a8f8e-549b-4982-86cc-375bf04104ff?pipeline=meadow-v1-Work
{
  "original": {
    "accession_number": "Canary_002",
    "action_states": {},
    "administrative_metadata": {
      "id": "8563a43e-fd18-4e2b-8f26-8b470d9d8df8",
      "inserted_at": "2022-03-02T20:38:29.813440Z",
      "library_unit": {
        "id": "SPECIAL_COLLECTIONS",
        "label": "Charles Deering McCormick Library of Special Collections",
        "scheme": "library_unit"
      },
      "preservation_level": {
        "id": "1",
        "label": "Level 1",
        "scheme": "preservation_level"
      },
      "project_cycle": "2020",
      "project_desc": [],
      "project_manager": [
        "Nicole Finzer"
      ],
      "project_name": [
        "Canary Project t"
      ],
      "project_proposer": [
        "Carolyn Caizzi"
      ],
      "project_task_number": [
        "P0000"
      ],
      "status": {
        "id": "DONE",
        "label": "Done",
        "scheme": "status"
      },
      "updated_at": "2022-03-02T20:38:29.813440Z"
    },
    "batches": [
      {
        "active": false,
        "delete": "{}",
        "error": null,
        "id": "a846a5f2-da57-49e6-a138-f5462d113a55",
        "inserted_at": "2022-03-02T22:13:46",
        "nickname": "Update Canary Records",
        "started": "2022-03-02T22:14:05.647282Z",
        "status": "complete",
        "type": "update",
        "updated_at": "2022-03-02T22:14:07",
        "user": "vlr6602",
        "works": {},
        "works_updated": 3
      }
    ],
    "collection": {
      "admin_email": "veronica.robinson@northwestern.edu",
      "description": "The Canary in the coal mine",
      "featured": false,
      "finding_aid_url": "https://findingaids.library.northwestern.edu/repositories/3/resources/1310",
      "id": "7c50096c-89eb-43e8-b357-5836a788ddeb",
      "inserted_at": "2022-03-02T20:20:34.438359Z",
      "keywords": [
        "Testing, Quality Assurance, Birds, Tacos"
      ],
      "published": false,
      "representative_image": null,
      "representative_work": {},
      "representative_work_id": "156a8f8e-549b-4982-86cc-375bf04104ff",
      "title": "TEST Canary Records",
      "updated_at": "2022-03-02T22:08:23.731896Z",
      "visibility": null,
      "works": {}
    },
    "collection_id": "7c50096c-89eb-43e8-b357-5836a788ddeb",
    "descriptive_metadata": {
      "physical_description_material": [
        "Acrylic paint on cement block"
      ],
      "related_material": [
        "See Also: related material"
      ],
      "ark": "ark:/99999/fk47h32p0m",
      "language": [
        {
          "role": null,
          "term": {
            "id": "http://id.loc.gov/vocabulary/languages/crh",
            "label": "Crimean Tatar",
            "variants": []
          }
        }
      ],
      "source": [
        "Mars"
      ],
      "identifier": [
        "555"
      ],
      "abstract": [
        "This is a brief description"
      ],
      "inserted_at": "2022-03-02T20:38:29.813480Z",
      "folder_name": [
        "Blue folder"
      ],
      "technique": [
        {
          "role": null,
          "term": {
            "id": "http://vocab.getty.edu/aat/300053228",
            "label": "drypoint (printing process)",
            "variants": []
          }
        }
      ],
      "id": "d4d15abe-2523-4028-a7e1-54eb71ff6d10",
      "catalog_key": [
        "MS-1984-1982-1989"
      ],
      "box_number": [
        "88"
      ],
      "contributor": [
        {
          "role": {
            "id": "ctg",
            "label": "Cartographer",
            "scheme": "marc_relator"
          },
          "term": {
            "id": "http://id.loc.gov/authorities/names/n91114928",
            "label": "Metallica (Musical group)",
            "variants": []
          }
        }
      ],
      "folder_number": [
        "88"
      ],
      "box_name": [
        "The name of a box"
      ],
      "style_period": [
        {
          "role": null,
          "term": {
            "id": "http://vocab.getty.edu/aat/300018478",
            "label": "Qing (dynastic styles and periods)",
            "variants": []
          }
        }
      ],
      "legacy_identifier": [
        "555"
      ],
      "provenance": [
        "Artist; sold to Mr. Blank in 1955; sold to Lancelot in 2017; gifted to Northwestern University in 2019"
      ],
      "alternate_title": [
        "This is an alternative title"
      ],
      "notes": [
        {
          "note": "Here are some notes",
          "type": {
            "id": "GENERAL_NOTE",
            "label": "General Note",
            "scheme": "note_type"
          }
        },
        {
          "note": "Awards type",
          "type": {
            "id": "AWARDS",
            "label": "Awards",
            "scheme": "note_type"
          }
        },
        {
          "note": "Biographical note",
          "type": {
            "id": "BIOGRAPHICAL_HISTORICAL_NOTE",
            "label": "Biographical/Historical Note",
            "scheme": "note_type"
          }
        },
        {
          "note": "creation production credits",
          "type": {
            "id": "CREATION_PRODUCTION_CREDITS",
            "label": "Creation/Production Credits",
            "scheme": "note_type"
          }
        },
        {
          "note": "Language note",
          "type": {
            "id": "LANGUAGE_NOTE",
            "label": "Language Note",
            "scheme": "note_type"
          }
        },
        {
          "note": "Local Note",
          "type": {
            "id": "LOCAL_NOTE",
            "label": "Local Note",
            "scheme": "note_type"
          }
        },
        {
          "note": "Performers",
          "type": {
            "id": "PERFORMERS",
            "label": "Performers",
            "scheme": "note_type"
          }
        },
        {
          "note": "Statement of Responsibility",
          "type": {
            "id": "STATEMENT_OF_RESPONSIBILITY",
            "label": "Statement of Responsibility",
            "scheme": "note_type"
          }
        },
        {
          "note": "Venue/event date",
          "type": {
            "id": "VENUE_EVENT_DATE",
            "label": "Venue/Event Date",
            "scheme": "note_type"
          }
        }
      ],
      "rights_statement": {
        "id": "http://rightsstatements.org/vocab/InC-EDU/1.0/",
        "label": "In Copyright - Educational Use Permitted",
        "scheme": "rights_statement"
      },
      "date_created": [
        {
          "edtf": "1906-08/1910-12",
          "humanized": "August 1906 to December 1910"
        }
      ],
      "cultural_context": [
        "Test Context"
      ],
      "table_of_contents": [
        "1. cats; 2. dogs"
      ],
      "keywords": [
        "leaves"
      ],
      "updated_at": "2022-03-02T20:38:29.813480Z",
      "series": [
        "Canaries and How to Care for Them"
      ],
      "rights_holder": [
        "Artist"
      ],
      "physical_description_size": [
        "16 x 24 inches"
      ],
      "title": "Canary Record TEST 1",
      "license": {
        "id": "http://www.europeana.eu/portal/rights/rr-r.html",
        "label": "All rights reserved",
        "scheme": "license"
      },
      "caption": [
        "Beebo"
      ],
      "genre": [
        {
          "role": null,
          "term": {
            "id": "http://vocab.getty.edu/aat/300435283",
            "label": "stencil prints",
            "variants": []
          }
        }
      ],
      "citation": [],
      "description": [
        "This is a private record for RepoDev testing on production"
      ],
      "terms_of_use": "Terms ",
      "related_url": [
        {
          "label": {
            "id": "FINDING_AID",
            "label": "Finding Aid",
            "scheme": "related_url"
          },
          "url": "https://findingaids.library.northwestern.edu/"
        },
        {
          "label": {
            "id": "RESEARCH_GUIDE",
            "label": "Research Guide",
            "scheme": "related_url"
          },
          "url": "https://www.wbez.org/"
        },
        {
          "label": {
            "id": "RELATED_INFORMATION",
            "label": "Related Information",
            "scheme": "related_url"
          },
          "url": "https://www.nationalgeographic.com/animals/mammals/facts/squirrels"
        },
        {
          "label": {
            "id": "HATHI_TRUST_DIGITAL_LIBRARY",
            "label": "Hathi Trust Digital Library",
            "scheme": "related_url"
          },
          "url": "https://www.hathitrust.org/"
        }
      ],
      "creator": [
        {
          "role": null,
          "term": {
            "id": "http://id.loc.gov/authorities/names/no2011059409",
            "label": "Dessa (Vocalist)",
            "variants": [
              "Dessa, 1981-",
              "Wander, Dessa, 1981-",
              "Dessa Darling",
              "Wander, Margret"
            ]
          }
        },
        {
          "role": null,
          "term": {
            "id": "http://id.worldcat.org/fast/1152763",
            "label": "Tornadoes",
            "variants": []
          }
        }
      ],
      "scope_and_contents": [
        "I promise there is scope and content"
      ],
      "publisher": [
        "Northwestern University Press"
      ],
      "subject": [
        {
          "role": {
            "id": "TOPICAL",
            "label": "Topical",
            "scheme": "subject_role"
          },
          "term": {
            "id": "http://id.worldcat.org/fast/1902713",
            "label": "Cats on postage stamps",
            "variants": []
          }
        },
        {
          "role": {
            "id": "TOPICAL",
            "label": "Topical",
            "scheme": "subject_role"
          },
          "term": {
            "id": "info:nul/6cba23b5-a91a-4c13-8398-54967b329d48",
            "label": "Test Record Canary",
            "variants": []
          }
        },
        {
          "role": {
            "id": "GEOGRAPHICAL",
            "label": "Geographical",
            "scheme": "subject_role"
          },
          "term": {
            "id": "http://vocab.getty.edu/tgn/2000971",
            "label": "Leelanau",
            "variants": []
          }
        },
        {
          "role": {
            "id": "GEOGRAPHICAL",
            "label": "Geographical",
            "scheme": "subject_role"
          },
          "term": {
            "id": "http://id.worldcat.org/fast/1204587",
            "label": "Michigan--Ann Arbor",
            "variants": []
          }
        }
      ],
      "location": [
        {
          "role": null,
          "term": {
            "id": "https://sws.geonames.org/4999069/",
            "label": "Leland Township",
            "variants": []
          }
        }
      ]
    },
    "file_sets": [
      {
        "accession_number": "Canary_002_001",
        "action_states": {},
        "core_metadata": {
          "description": "Access File - Tiff",
          "digests": {
            "md5": "28984febc66027ec31d0715e472be8a9"
          },
          "id": "49b6a724-cd26-40f4-879d-85ad6d983db6",
          "inserted_at": "2022-03-02T20:39:07.892460Z",
          "label": "Access File - Tiff",
          "location": "s3://meadow-s-preservation/07/6d/cb/d8/076dcbd8-8c57-40e8-bdf7-dc9153c87a36",
          "mime_type": "image/tiff",
          "original_filename": "Squirrel.tif",
          "updated_at": "2022-03-02T20:39:07.892460Z"
        },
        "derivatives": {
          "pyramid_tiff": "s3://stack-s-pyramid-tiffs/07/6d/cb/d8/-8/c5/7-/40/e8/-b/df/7-/dc/91/53/c8/7a/36-pyramid.tif"
        },
        "extracted_metadata": {
          "exif": {
            "tool": "exifr",
            "tool_version": "6.1.1",
            "value": {
              "bitsPerSample": "8, 8, 8",
              "compression": "Uncompressed",
              "imageHeight": 3024,
              "imageWidth": 4032,
              "make": "Google",
              "model": "Pixel 4a",
              "orientation": "Horizontal (normal)",
              "photometricInterpretation": "RGB",
              "planarConfiguration": "Chunky",
              "resolutionUnit": "inches",
              "samplesPerPixel": 3,
              "software": "Adobe Photoshop 23.0 (Windows)",
              "subfileType": "Full-resolution image",
              "xResolution": 72,
              "yResolution": 72
            }
          }
        },
        "id": "076dcbd8-8c57-40e8-bdf7-dc9153c87a36",
        "inserted_at": "2022-03-02T20:39:07.892477Z",
        "position": null,
        "poster_offset": null,
        "rank": 0,
        "role": {
          "id": "A",
          "label": "Access",
          "scheme": "file_set_role"
        },
        "structural_metadata": {
          "type": null,
          "value": null
        },
        "updated_at": "2022-03-02T20:39:19.633123Z",
        "work": {},
        "work_id": "156a8f8e-549b-4982-86cc-375bf04104ff"
      },
      {
        "accession_number": "Canary_002_002",
        "action_states": {},
        "core_metadata": {
          "description": "Access File - Tiff",
          "digests": {
            "md5": "79ec95c16fe510f8592f614304d518f4"
          },
          "id": "ee1effa5-6214-4ea3-8995-b06d42fb667b",
          "inserted_at": "2022-03-02T20:39:45.435343Z",
          "label": "Access File - Tiff",
          "location": "s3://meadow-s-preservation/d5/1c/c0/b6/d51cc0b6-562a-4a8f-8443-5e20221c308b",
          "mime_type": "image/tiff",
          "original_filename": "PXL_20211203_142315620.tif",
          "updated_at": "2022-03-02T20:39:45.435343Z"
        },
        "derivatives": {
          "pyramid_tiff": "s3://stack-s-pyramid-tiffs/d5/1c/c0/b6/-5/62/a-/4a/8f/-8/44/3-/5e/20/22/1c/30/8b-pyramid.tif"
        },
        "extracted_metadata": {
          "exif": {
            "tool": "exifr",
            "tool_version": "6.1.1",
            "value": {
              "bitsPerSample": "8, 8, 8",
              "compression": "Uncompressed",
              "imageHeight": 3024,
              "imageWidth": 4032,
              "make": "Google",
              "model": "Pixel 4a",
              "orientation": "Horizontal (normal)",
              "photometricInterpretation": "RGB",
              "planarConfiguration": "Chunky",
              "resolutionUnit": "inches",
              "samplesPerPixel": 3,
              "software": "Adobe Photoshop 23.0 (Windows)",
              "subfileType": "Full-resolution image",
              "xResolution": 72,
              "yResolution": 72
            }
          }
        },
        "id": "d51cc0b6-562a-4a8f-8443-5e20221c308b",
        "inserted_at": "2022-03-02T20:39:45.435359Z",
        "position": null,
        "poster_offset": null,
        "rank": 1073741824,
        "role": {
          "id": "A",
          "label": "Access",
          "scheme": "file_set_role"
        },
        "structural_metadata": {
          "type": null,
          "value": null
        },
        "updated_at": "2022-03-02T20:39:58.057736Z",
        "work": {},
        "work_id": "156a8f8e-549b-4982-86cc-375bf04104ff"
      },
      {
        "accession_number": "Canary_002_005",
        "action_states": {},
        "core_metadata": {
          "description": "Preservation File - Tiff",
          "digests": {
            "md5": "1dfac579fbd9bc0dce855061caff6cc9"
          },
          "id": "9e332cda-9d04-4707-9a74-156f2167e109",
          "inserted_at": "2022-03-02T20:43:01.414207Z",
          "label": "Preservation File - Tiff",
          "location": "s3://meadow-s-preservation/5a/4f/fc/fb/5a4ffcfb-e231-4a59-9e4d-92d1814604fb",
          "mime_type": "image/tiff",
          "original_filename": "distillery.tif",
          "updated_at": "2022-03-02T20:43:01.414207Z"
        },
        "derivatives": {},
        "extracted_metadata": {
          "exif": {
            "tool": "exifr",
            "tool_version": "6.1.1",
            "value": {
              "bitsPerSample": "8, 8, 8",
              "compression": "Uncompressed",
              "imageHeight": 4032,
              "imageWidth": 3024,
              "make": "Google",
              "model": "Pixel 4a",
              "orientation": "Horizontal (normal)",
              "photometricInterpretation": "RGB",
              "planarConfiguration": "Chunky",
              "resolutionUnit": "inches",
              "samplesPerPixel": 3,
              "software": "Adobe Photoshop 23.0 (Windows)",
              "subfileType": "Full-resolution image",
              "xResolution": 72,
              "yResolution": 72
            }
          }
        },
        "id": "5a4ffcfb-e231-4a59-9e4d-92d1814604fb",
        "inserted_at": "2022-03-02T20:43:01.414223Z",
        "position": null,
        "poster_offset": null,
        "rank": 1073741824,
        "role": {
          "id": "P",
          "label": "Preservation",
          "scheme": "file_set_role"
        },
        "structural_metadata": {
          "type": null,
          "value": null
        },
        "updated_at": "2022-03-02T20:43:11.238998Z",
        "work": {},
        "work_id": "156a8f8e-549b-4982-86cc-375bf04104ff"
      },
      {
        "accession_number": "Canary_002_003",
        "action_states": {},
        "core_metadata": {
          "description": "Access File - Jpeg",
          "digests": {
            "md5": "8f58e42857baedf8e37f4658f154db5f"
          },
          "id": "39cf6e7a-63a3-4b2b-a0c4-72c902226e37",
          "inserted_at": "2022-03-02T20:40:55.742589Z",
          "label": "Access File - Jpeg",
          "location": "s3://meadow-s-preservation/51/86/2c/1c/51862c1c-c024-45dc-ab26-694bd8ebc16c",
          "mime_type": "image/jpeg",
          "original_filename": "Cassettetape.jpg",
          "updated_at": "2022-03-02T20:40:55.742589Z"
        },
        "derivatives": {
          "pyramid_tiff": "s3://stack-s-pyramid-tiffs/51/86/2c/1c/-c/02/4-/45/dc/-a/b2/6-/69/4b/d8/eb/c1/6c-pyramid.tif"
        },
        "extracted_metadata": {
          "exif": {
            "tool": "exifr",
            "tool_version": "6.1.1",
            "value": {
              "copyright": "GeoffBlack",
              "imageDescription": "Audio Cassette Mix Tape. More Audio Cassettes are here..."
            }
          }
        },
        "id": "51862c1c-c024-45dc-ab26-694bd8ebc16c",
        "inserted_at": "2022-03-02T20:40:55.742607Z",
        "position": null,
        "poster_offset": null,
        "rank": 1610612736,
        "role": {
          "id": "A",
          "label": "Access",
          "scheme": "file_set_role"
        },
        "structural_metadata": {
          "type": null,
          "value": null
        },
        "updated_at": "2022-03-02T20:41:08.082379Z",
        "work": {},
        "work_id": "156a8f8e-549b-4982-86cc-375bf04104ff"
      },
      {
        "accession_number": "Canary_002_004",
        "action_states": {},
        "core_metadata": {
          "description": "Preservation File - Jpeg",
          "digests": {
            "md5": "8f58e42857baedf8e37f4658f154db5f"
          },
          "id": "b4607040-e939-46da-805f-739253928bbf",
          "inserted_at": "2022-03-02T20:42:09.646781Z",
          "label": "Preservation File - Jpeg",
          "location": "s3://meadow-s-preservation/a1/0c/18/29/a10c1829-265c-44cf-996a-f8c59b16ba97",
          "mime_type": "image/jpeg",
          "original_filename": "Cassettetape.jpg",
          "updated_at": "2022-03-02T20:42:09.646781Z"
        },
        "derivatives": {},
        "extracted_metadata": {
          "exif": {
            "tool": "exifr",
            "tool_version": "6.1.1",
            "value": {
              "copyright": "GeoffBlack",
              "imageDescription": "Audio Cassette Mix Tape. More Audio Cassettes are here..."
            }
          }
        },
        "id": "a10c1829-265c-44cf-996a-f8c59b16ba97",
        "inserted_at": "2022-03-02T20:42:09.646798Z",
        "position": null,
        "poster_offset": null,
        "rank": 0,
        "role": {
          "id": "P",
          "label": "Preservation",
          "scheme": "file_set_role"
        },
        "structural_metadata": {
          "type": null,
          "value": null
        },
        "updated_at": "2022-03-02T20:42:18.544889Z",
        "work": {},
        "work_id": "156a8f8e-549b-4982-86cc-375bf04104ff"
      },
      {
        "accession_number": "Canary_002_006",
        "action_states": {},
        "core_metadata": {
          "description": "Auxiliary File - PNG",
          "digests": {
            "md5": "8790391466a3ea69fdd15e542eeb7f37"
          },
          "id": "b6314eb2-cdb3-4c17-ac1c-6834aa15c2b9",
          "inserted_at": "2022-03-02T20:46:05.000970Z",
          "label": "Auxiliary File - PNG",
          "location": "s3://meadow-s-preservation/09/61/7d/98/09617d98-9c67-414e-a0f7-4e69ca99546b",
          "mime_type": "image/jpeg",
          "original_filename": "CoopersHawk.png",
          "updated_at": "2022-03-02T20:46:05.000970Z"
        },
        "derivatives": {
          "pyramid_tiff": "s3://stack-s-pyramid-tiffs/09/61/7d/98/-9/c6/7-/41/4e/-a/0f/7-/4e/69/ca/99/54/6b-pyramid.tif"
        },
        "extracted_metadata": {
          "exif": {
            "tool": "exifr",
            "tool_version": "6.1.1",
            "value": {
              "make": "NIKON CORPORATION",
              "model": "NIKON D3400",
              "orientation": "Horizontal (normal)",
              "resolutionUnit": "inches",
              "software": "Ver.1.10",
              "xResolution": 300,
              "yResolution": 300
            }
          }
        },
        "id": "09617d98-9c67-414e-a0f7-4e69ca99546b",
        "inserted_at": "2022-03-02T20:46:05.000988Z",
        "position": null,
        "poster_offset": null,
        "rank": 0,
        "role": {
          "id": "X",
          "label": "Auxiliary",
          "scheme": "file_set_role"
        },
        "structural_metadata": {
          "type": null,
          "value": null
        },
        "updated_at": "2022-03-02T20:46:17.149696Z",
        "work": {},
        "work_id": "156a8f8e-549b-4982-86cc-375bf04104ff"
      },
      {
        "accession_number": "Canary_002_007",
        "action_states": {},
        "core_metadata": {
          "description": "Supplemental File - txt",
          "digests": {
            "md5": "5b680164d865c28cfdb530b10e68efd7"
          },
          "id": "4192eb47-889c-411d-9cdb-73f52cf6c7ec",
          "inserted_at": "2022-03-02T20:47:41.434217Z",
          "label": "Supplemental File - txt",
          "location": "s3://meadow-s-preservation/37/cc/45/40/37cc4540-ecd0-48d0-a438-a255850b9221",
          "mime_type": "text/plain",
          "original_filename": "Test.txt",
          "updated_at": "2022-03-02T20:47:41.434217Z"
        },
        "derivatives": {},
        "extracted_metadata": {},
        "id": "37cc4540-ecd0-48d0-a438-a255850b9221",
        "inserted_at": "2022-03-02T20:47:41.434234Z",
        "position": null,
        "poster_offset": null,
        "rank": 0,
        "role": {
          "id": "S",
          "label": "Supplemental",
          "scheme": "file_set_role"
        },
        "structural_metadata": {
          "type": null,
          "value": null
        },
        "updated_at": "2022-03-02T20:47:48.488292Z",
        "work": {},
        "work_id": "156a8f8e-549b-4982-86cc-375bf04104ff"
      }
    ],
    "id": "156a8f8e-549b-4982-86cc-375bf04104ff",
    "ingest_sheet": null,
    "ingest_sheet_id": null,
    "inserted_at": "2022-03-02T20:38:29.813494Z",
    "metadata_update_jobs": [
      {
        "active": false,
        "errors": [],
        "filename": "TestCanary_update.csv",
        "id": "5753101a-42fa-4838-9b71-f1594a5b1d5f",
        "inserted_at": "2022-03-02T21:27:05.415571Z",
        "retries": 0,
        "rows": 3,
        "source": "s3://meadow-s-uploads/csv_metadata/ec58c1e0-0b9e-493c-ae4e-604876940e83.csv",
        "started_at": "2022-03-02T21:27:07.000000Z",
        "status": "complete",
        "updated_at": "2022-03-02T21:27:06.947259Z",
        "user": "vlr6602"
      },
      {
        "active": false,
        "errors": [],
        "filename": "TestCanary_update2.csv",
        "id": "6b46db60-6f6a-45e8-8b8d-ab0029a1e8fe",
        "inserted_at": "2022-03-02T22:07:58.041769Z",
        "retries": 0,
        "rows": 3,
        "source": "s3://meadow-s-uploads/csv_metadata/8e4372cf-37d7-453f-b675-3ee9e69f56f9.csv",
        "started_at": "2022-03-02T22:07:59.000000Z",
        "status": "complete",
        "updated_at": "2022-03-02T22:07:58.620932Z",
        "user": "vlr6602"
      },
      {
        "active": false,
        "errors": [],
        "filename": "all_items.csv",
        "id": "38988b3e-5778-41da-85a5-e16d13cb098a",
        "inserted_at": "2022-05-23T15:33:19.812847Z",
        "retries": 0,
        "rows": 3,
        "source": "s3://meadow-s-uploads/csv_metadata/fb498dde-a206-4c30-9b5f-7bfdd43e592a.csv",
        "started_at": "2022-05-23T15:33:20.000000Z",
        "status": "complete",
        "updated_at": "2022-05-23T15:33:20.036633Z",
        "user": "vlr6602"
      }
    ],
    "project": null,
    "published": true,
    "reading_room": false,
    "representative_file_set": {
      "accession_number": "Canary_002_001",
      "action_states": {},
      "core_metadata": {
        "description": "Access File - Tiff",
        "digests": {
          "md5": "28984febc66027ec31d0715e472be8a9"
        },
        "id": "49b6a724-cd26-40f4-879d-85ad6d983db6",
        "inserted_at": "2022-03-02T20:39:07.892460Z",
        "label": "Access File - Tiff",
        "location": "s3://meadow-s-preservation/07/6d/cb/d8/076dcbd8-8c57-40e8-bdf7-dc9153c87a36",
        "mime_type": "image/tiff",
        "original_filename": "Squirrel.tif",
        "updated_at": "2022-03-02T20:39:07.892460Z"
      },
      "derivatives": {
        "pyramid_tiff": "s3://stack-s-pyramid-tiffs/07/6d/cb/d8/-8/c5/7-/40/e8/-b/df/7-/dc/91/53/c8/7a/36-pyramid.tif"
      },
      "extracted_metadata": {
        "exif": {
          "tool": "exifr",
          "tool_version": "6.1.1",
          "value": {
            "BitsPerSample": {
              "0": 8,
              "1": 8,
              "2": 8
            },
            "Compression": 1,
            "ImageHeight": 3024,
            "ImageWidth": 4032,
            "Make": "Google",
            "Model": "Pixel 4a",
            "Orientation": "Horizontal (normal)",
            "PhotometricInterpretation": 2,
            "PlanarConfiguration": 1,
            "ResolutionUnit": "inches",
            "SamplesPerPixel": 3,
            "Software": "Adobe Photoshop 23.0 (Windows)",
            "SubfileType": 0,
            "XResolution": 72,
            "YResolution": 72
          }
        }
      },
      "id": "076dcbd8-8c57-40e8-bdf7-dc9153c87a36",
      "inserted_at": "2022-03-02T20:39:07.892477Z",
      "position": null,
      "poster_offset": null,
      "rank": 0,
      "role": {
        "id": "A",
        "label": "Access",
        "scheme": "file_set_role"
      },
      "structural_metadata": {
        "type": null,
        "value": null
      },
      "updated_at": "2022-03-02T20:39:19.633123Z",
      "work": {},
      "work_id": "156a8f8e-549b-4982-86cc-375bf04104ff"
    },
    "representative_file_set_id": "076dcbd8-8c57-40e8-bdf7-dc9153c87a36",
    "representative_image": "https://iiif.stack.rdc-staging.library.northwestern.edu/iiif/2/076dcbd8-8c57-40e8-bdf7-dc9153c87a36",
    "updated_at": "2022-05-23T15:33:20.031314Z",
    "visibility": {
      "id": "OPEN",
      "label": "Public",
      "scheme": "visibility"
    },
    "work_type": {
      "id": "IMAGE",
      "label": "Image",
      "scheme": "work_type"
    }
  }
}
