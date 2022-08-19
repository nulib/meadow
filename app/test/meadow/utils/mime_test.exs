defmodule Meadow.Utils.MIMETest do
  use ExUnit.Case

  alias Meadow.Utils.MIME

  # Can't simply doctest because it won't pick up the configured custom types

  test "get a MIME type known to the MIME package" do
    assert MIME.from_path("/path/to/image.tiff") == "image/tiff"
    assert MIME.type("tiff") == "image/tiff"
  end

  test "get a MIME type known to Meadow but not the MIME package" do
    assert MIME.from_path("/path/to/image.framemd5") == "text/plain"
    assert MIME.type("framemd5") == "text/plain"
  end

  test "return application/octet-stream for unknown file type" do
    assert MIME.from_path("/path/to/unknown.blorb") == "application/octet-stream"
    assert MIME.type("blorb") == "application/octet-stream"
  end
end
