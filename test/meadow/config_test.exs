defmodule Meadow.ConfigTest do
  use ExUnit.Case
  alias Meadow.Config

  test "index_interval/0" do
    assert Config.index_interval() == 1234
  end

  test "ingest_bucket" do
    assert Config.ingest_bucket() == "test-ingest"
  end

  test "preservation_bucket" do
    assert Config.preservation_bucket() == "test-preservation"
  end

  test "upload_bucket" do
    assert Config.upload_bucket() == "test-uploads"
  end

  test "pyramid_bucket" do
    assert Config.pyramid_bucket() == "test-pyramids"
  end

  test "pyramid_processor" do
    assert Path.basename(Config.pyramid_processor()) == "fake_pyramid.js"
  end

  test "buckets" do
    assert Config.buckets() == [
             "test-ingest",
             "test-preservation",
             "test-uploads",
             "test-pyramids"
           ]
  end

  test "test_mode?" do
    assert Config.test_mode?() == true
  end
end
