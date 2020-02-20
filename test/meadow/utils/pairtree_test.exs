defmodule Meadow.Utils.PairtreeTest do
  use ExUnit.Case
  alias Meadow.Utils.Pairtree
  import ExUnit.DocTest

  doctest Meadow.Utils.Pairtree, import: true

  describe "generate/2" do
    test "full length" do
      assert Pairtree.generate("ABCDEFGH") == {:ok, "ab/cd/ef/gh"}
    end

    test "odd number of characters" do
      assert Pairtree.generate("ABCDEFG") == {:ok, "ab/cd/ef"}
    end

    test "partial" do
      assert Pairtree.generate("ABCDEFGH", 3) == {:ok, "ab/cd/ef"}
    end

    test "too short for partial" do
      assert Pairtree.generate("ABCDEFGH", 8) == {:ok, "ab/cd/ef/gh"}
    end

    test "bad length" do
      assert Pairtree.generate("ABCDEFGH", "foo") == {:error, "length must be nil or integer"}
    end
  end

  describe "generate!/2" do
    test "full length" do
      assert Pairtree.generate!("ABCDEFGH") == "ab/cd/ef/gh"
    end

    test "odd number of characters" do
      assert Pairtree.generate!("ABCDEFG") == "ab/cd/ef"
    end

    test "partial" do
      assert Pairtree.generate!("ABCDEFGH", 3) == "ab/cd/ef"
    end

    test "too short for partial" do
      assert Pairtree.generate!("ABCDEFGH", 8) == "ab/cd/ef/gh"
    end

    test "bad length" do
      assert_raise ArgumentError, "length must be nil or integer", fn ->
        Pairtree.generate!("ABCDEFGH", "foo")
      end
    end
  end

  describe "generate_pyramid_path/1" do
    assert Pairtree.generate_pyramid_path("a13d45b1-69a6-447f-9d42-90b989a2949c") ==
             "a1/3d/45/b1/-6/9a/6-/44/7f/-9/d4/2-/90/b9/89/a2/94/9c-pyramid.tif"
  end
end
