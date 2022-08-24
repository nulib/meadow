ctx.file_sets = ctx.original.fileSets
  .stream()
  .map(fs -> {
    def result = [:];
    // result.extracted_metadata = fs.extractedMetadata;
    result.id = fs.id;
    result.label = fs.label;
    result.mime_type = fs.mime_type;
    result.original_filename = fs.original_filename;
    result.poster_offset = fs.posterOffset;
    result.rank = fs.rank;
    result.representative_image_url = fs.representativeImageUrl;
    result.role = fs.role.label;
    result.streaming_url = fs.streamingUrl;
    return result;
  })
  .collect(Collectors.toList());
