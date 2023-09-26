defmodule Meadow.ConfigTest do
  use ExUnit.Case
  use Meadow.BucketNames

  alias Elixir.Config.Reader, as: ConfigReader
  alias Meadow.Config
  import Assertions

  test "index_interval/0" do
    assert Config.index_interval() == 1234
  end

  test "ingest_bucket/0" do
    assert Config.ingest_bucket() == @ingest_bucket
  end

  test "preservation_bucket/0" do
    assert Config.preservation_bucket() == @preservation_bucket
  end

  test "upload_bucket/0" do
    assert Config.upload_bucket() == @upload_bucket
  end

  test "pyramid_bucket/0" do
    assert Config.pyramid_bucket() == @pyramid_bucket
  end

  test "preservation_check_bucket/0" do
    assert Config.preservation_check_bucket() == @preservation_check_bucket
  end

  test "lambda_config/1" do
    assert {:local, {script, handler}} = Config.lambda_config(:exif)
    assert script =~ ~r(lambdas/exif/index.js$)
    assert handler == "handler"

    assert Config.lambda_config(:missing) == {:error, :unknown}
  end

  test "buckets/0" do
    [
      @ingest_bucket,
      @preservation_bucket,
      @upload_bucket,
      @pyramid_bucket,
      @preservation_check_bucket,
      @streaming_bucket
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
    with env <- Config.aws_environment() |> Enum.into(%{}) do
      assert env |> Map.has_key?('TMPDIR')

      if Application.get_env(:ex_aws, :s3) do
        assert env |> Map.get('AWS_REGION') == 'us-east-1'
        assert env |> Map.get('AWS_SECRET_ACCESS_KEY') == 'fake'
        assert env |> Map.get('AWS_ACCESS_KEY_ID') == 'fake'
        assert env |> Map.get('AWS_S3_ENDPOINT') |> Enum.slice(0..15) == 'http://localhost'
      end
    end
  end

  test "meadow_version/0" do
    assert Config.meadow_version() == Mix.Project.config() |> Keyword.get(:version)
  end

  describe "IIIF configs" do
    setup do
      prior_values = %{
        server: Application.get_env(:meadow, :iiif_server_url),
        manifest: Application.get_env(:meadow, :iiif_manifest_url_deprecated)
      }

      on_exit(fn ->
        Application.put_env(:meadow, :iiif_server_url, prior_values.server)
        Application.put_env(:meadow, :iiif_manifest_url_deprecated, prior_values.manifest)
      end)
    end

    test "trailing slashes/0" do
      Application.put_env(:meadow, :iiif_server_url, "http://no-slash-test/iiif/2")

      Application.put_env(
        :meadow,
        :iiif_manifest_url_deprecated,
        "http://no-slash-test/minio/test-pyramids/public"
      )

      assert Config.iiif_server_url() == "http://no-slash-test/iiif/2/"

      assert Config.iiif_manifest_url_deprecated() ==
               "http://no-slash-test/minio/test-pyramids/public/"
    end

    test "validate release config" do
      System.put_env("__COMPILE_CHECK__", "TRUE")
      assert ConfigReader.read!("config/releases.exs") |> is_list()
    after
      System.delete_env("__COMPILE_CHECK__")
    end
  end
end
