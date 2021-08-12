defmodule Meadow.ConfigTest do
  use ExUnit.Case
  alias Elixir.Config.Reader, as: ConfigReader
  alias Meadow.Config
  import Assertions

  test "index_interval/0" do
    assert Config.index_interval() == 1234
  end

  test "ingest_bucket/0" do
    assert Config.ingest_bucket() == "test-ingest"
  end

  test "preservation_bucket/0" do
    assert Config.preservation_bucket() == "test-preservation"
  end

  test "upload_bucket/0" do
    assert Config.upload_bucket() == "test-uploads"
  end

  test "pyramid_bucket/0" do
    assert Config.pyramid_bucket() == "test-pyramids"
  end

  test "preservation_check_bucket/0" do
    assert Config.preservation_check_bucket() == "test-preservation-checks"
  end

  test "lambda_config/1" do
    assert {:local, {script, handler}} = Config.lambda_config(:edtf)
    assert script =~ ~r(priv/nodejs/edtf/index.js$)
    assert handler == "handler"

    assert Config.lambda_config(:missing) == {:error, :unknown}
  end

  test "buckets/0" do
    [
      "test-ingest",
      "test-preservation",
      "test-uploads",
      "test-pyramids",
      "test-preservation-checks",
      "test-streaming"
    ]
    |> assert_lists_equal(Config.buckets())
  end

  test "environment/0" do
    assert Config.environment() == :test
  end

  test "environment?/1" do
    assert Config.environment?(:test)
    refute Config.environment?(:dev)
  end

  test "aws_environment/0" do
    get_val = fn env, key ->
      env
      |> Enum.find_value(fn
        {^key, v} -> v
        _ -> nil
      end)
    end

    with env <- Config.aws_environment() do
      assert env |> get_val.('AWS_REGION') == 'us-east-1'
      assert env |> get_val.('AWS_SECRET_ACCESS_KEY') == 'minio123'
      assert env |> get_val.('AWS_ACCESS_KEY_ID') == 'minio'
      assert env |> get_val.('AWS_S3_ENDPOINT') |> Enum.slice(0..16) == 'http://localhost:'
    end
  end

  test "meadow_version/0" do
    assert Config.meadow_version() == Mix.Project.config() |> Keyword.get(:version)
  end

  describe "IIIF configs" do
    setup do
      prior_values = %{
        server: Application.get_env(:meadow, :iiif_server_url),
        manifest: Application.get_env(:meadow, :iiif_manifest_url)
      }

      on_exit(fn ->
        Application.put_env(:meadow, :iiif_server_url, prior_values.server)
        Application.put_env(:meadow, :iiif_manifest_url, prior_values.manifest)
      end)
    end

    test "iiif_server_url/0" do
      assert Config.iiif_server_url() == "http://localhost:8184/iiif/2/"
    end

    test "iiif_manifest_url/0" do
      assert Config.iiif_manifest_url() == "http://localhost:9002/minio/test-pyramids/public/"
    end

    test "trailing slashes/0" do
      Application.put_env(:meadow, :iiif_server_url, "http://no-slash-test/iiif/2")

      Application.put_env(
        :meadow,
        :iiif_manifest_url,
        "http://no-slash-test/minio/test-pyramids/public"
      )

      assert Config.iiif_server_url() == "http://no-slash-test/iiif/2/"
      assert Config.iiif_manifest_url() == "http://no-slash-test/minio/test-pyramids/public/"
    end

    test "validate release config" do
      System.put_env("__COMPILE_CHECK__", "TRUE")
      assert ConfigReader.read!("config/releases.exs") |> is_list()
    after
      System.delete_env("__COMPILE_CHECK__")
    end
  end
end
