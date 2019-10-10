defmodule ArnTest do
  use ExUnit.Case
  alias SQNS.Utils.Arn

  @arn "arn:aws:s3:us-east-1:123456789012:abcdefg/hijkl"

  describe "arns" do
    test "parses an ARN" do
      arn = Arn.parse(@arn)

      assert(arn.scheme == "arn")
      assert(arn.partition == "aws")
      assert(arn.service == "s3")
      assert(arn.region == "us-east-1")
      assert(arn.account == "123456789012")
      assert(arn.resource == "abcdefg/hijkl")
    end

    test "updates scheme" do
      arn = Arn.parse(@arn) |> Arn.update_scheme("UPDATED")
      assert(arn.scheme == "UPDATED")
      assert(arn.partition == "aws")
      assert(arn.service == "s3")
      assert(arn.region == "us-east-1")
      assert(arn.account == "123456789012")
      assert(arn.resource == "abcdefg/hijkl")
    end

    test "updates partition" do
      arn = Arn.parse(@arn) |> Arn.update_partition("UPDATED")
      assert(arn.scheme == "arn")
      assert(arn.partition == "UPDATED")
      assert(arn.service == "s3")
      assert(arn.region == "us-east-1")
      assert(arn.account == "123456789012")
      assert(arn.resource == "abcdefg/hijkl")
    end

    test "updates service" do
      arn = Arn.parse(@arn) |> Arn.update_service("UPDATED")
      assert(arn.scheme == "arn")
      assert(arn.partition == "aws")
      assert(arn.service == "UPDATED")
      assert(arn.region == "us-east-1")
      assert(arn.account == "123456789012")
      assert(arn.resource == "abcdefg/hijkl")
    end

    test "updates region" do
      arn = Arn.parse(@arn) |> Arn.update_region("UPDATED")
      assert(arn.scheme == "arn")
      assert(arn.partition == "aws")
      assert(arn.service == "s3")
      assert(arn.region == "UPDATED")
      assert(arn.account == "123456789012")
      assert(arn.resource == "abcdefg/hijkl")
    end

    test "updates account" do
      arn = Arn.parse(@arn) |> Arn.update_account("UPDATED")
      assert(arn.scheme == "arn")
      assert(arn.partition == "aws")
      assert(arn.service == "s3")
      assert(arn.region == "us-east-1")
      assert(arn.account == "UPDATED")
      assert(arn.resource == "abcdefg/hijkl")
    end

    test "updates resource" do
      arn = Arn.parse(@arn) |> Arn.update_resource("UPDATED")
      assert(arn.scheme == "arn")
      assert(arn.partition == "aws")
      assert(arn.service == "s3")
      assert(arn.region == "us-east-1")
      assert(arn.account == "123456789012")
      assert(arn.resource == "UPDATED")
    end
  end
end
