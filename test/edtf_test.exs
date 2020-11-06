defmodule EDTFTest do
  use ExUnit.Case

  import ExUnit.DocTest

  doctest EDTF, import: true

  test "validate/1" do
    assert EDTF.validate("2020") == {:ok, "2020"}
    assert EDTF.validate("bad date!") == {:error, "Invalid EDTF input: bad date!"}
  end

  test "parse/1" do
    assert EDTF.parse("2020") == {:ok, %{level: 0, type: "Date", values: [2020]}}
    assert EDTF.parse("bad date!") == {:error, "Invalid EDTF input: bad date!"}
  end

  describe "humanize/1" do
    test "invalid date" do
      assert EDTF.humanize("bad date!") == {:error, "Invalid EDTF input: bad date!"}
    end

    test "simple date" do
      assert EDTF.humanize("2020-06-10") == "June 10, 2020"
      assert EDTF.humanize("2020-06") == "June 2020"
      assert EDTF.humanize("2020") == "2020"
      assert EDTF.humanize("-2020-06") == "June 2020 BCE"
    end

    test "approximate date" do
      assert EDTF.humanize("2020-06-10~") == "circa June 10, 2020"
      assert EDTF.humanize("2020-06~") == "circa June 2020"
      assert EDTF.humanize("2020~") == "circa 2020"
      assert EDTF.humanize("-2020-06~") == "circa June 2020 BCE"
    end

    test "uncertain date" do
      assert EDTF.humanize("2020-06-10?") == "June 10, 2020?"
      assert EDTF.humanize("2020-06?") == "June 2020?"
      assert EDTF.humanize("2020?") == "2020?"
      assert EDTF.humanize("-2020-06?") == "June 2020 BCE?"
    end

    test "approximate and uncertain date" do
      assert EDTF.humanize("2020-06-10%") == "circa June 10, 2020?"
      assert EDTF.humanize("2020-06%") == "circa June 2020?"
      assert EDTF.humanize("2020%") == "circa 2020?"
      assert EDTF.humanize("-2020-06%") == "circa June 2020 BCE?"
    end

    test "dates with unspecified digits from the right" do
      assert EDTF.humanize("192X") == "1920s"
      assert EDTF.humanize("19XX") == "1900s"
      assert EDTF.humanize("1XXX") == "1000s"

      assert EDTF.humanize("-192X") == "1920s BCE"
      assert EDTF.humanize("-19XX") == "1900s BCE"
      assert EDTF.humanize("-1XXX") == "1000s BCE"
    end

    test "intervals with unspecified digits from the right" do
      assert EDTF.humanize("192X/193X") == "1920s to 1930s"
      assert EDTF.humanize("-192X/192X") == "1920s BCE to 1920s"
    end

    test "dates with other unspecified digits" do
      assert EDTF.humanize("X9X2") == "X9X2"
      assert EDTF.humanize("1999-XX") == "1999-XX"
      assert EDTF.humanize("1999-12-XX") == "1999-12-XX"
      assert EDTF.humanize("-19X9-12-XX") == "-19X9-12-XX"
    end

    test "prefixed and exponential years" do
      assert EDTF.humanize("Y20020") == "20020"
      assert EDTF.humanize("Y-20020") == "20020 BCE"
      assert EDTF.humanize("Y17E7") == "170000000"
      assert EDTF.humanize("Y-17E7") == "170000000 BCE"
    end

    test "decade" do
      assert EDTF.humanize("201") == "2010s"
      assert EDTF.humanize("-201") == "2010s BCE"
    end

    test "century" do
      assert EDTF.humanize("20") == "20th Century"
      assert EDTF.humanize("21") == "21st Century"
      assert EDTF.humanize("-20") == "20th Century BCE"
      assert EDTF.humanize("-21") == "21st Century BCE"
    end

    test "date interval" do
      assert EDTF.humanize("2019-06~/2020") == "circa June 2019 to 2020"
    end

    test "unbounded interval" do
      assert EDTF.humanize("2019-06~/..") == "from circa June 2019"
      assert EDTF.humanize("../2019-06-10~") == "before circa June 10, 2019"
    end

    test "interval with unknown bound" do
      assert EDTF.humanize("2019-06~/") == "circa June 2019 to Unknown"
      assert EDTF.humanize("/2019-06-10~") == "Unknown to circa June 10, 2019"
    end

    test "set" do
      assert EDTF.humanize("[2019-06]") == "June 2019"
      assert EDTF.humanize("[2019-06, 2020-06]") == "June 2019 or June 2020"
      assert EDTF.humanize("[2019-06, 2020-06, 2021-06]") == "June 2019, June 2020, or June 2021"

      assert EDTF.humanize("[2019-06, 2020-06, 2021-06..2021-07]") ==
               "June 2019, June 2020, or June 2021 to July 2021"

      assert EDTF.humanize("[..2020]") == "some year before 2020 or 2020"
      assert EDTF.humanize("[..2020-06]") == "some month before June 2020 or June 2020"
      assert EDTF.humanize("[..2020-06-10]") == "some date before June 10, 2020 or June 10, 2020"
      assert EDTF.humanize("[2020..]") == "2020 or some year after 2020"
      assert EDTF.humanize("[2020-06..]") == "June 2020 or some month after June 2020"
      assert EDTF.humanize("[2020-06-10..]") == "June 10, 2020 or some date after June 10, 2020"

      assert EDTF.humanize("[..2018, 2020-06-10..]") ==
               "some year before 2018, 2018, June 10, 2020, or some date after June 10, 2020"
    end

    test "list" do
      assert EDTF.humanize("{2019-06}") == "June 2019"
      assert EDTF.humanize("{2019-06, 2020-06}") == "June 2019 and June 2020"
      assert EDTF.humanize("{2019-06, 2020-06, 2021-06}") == "June 2019, June 2020, and June 2021"

      assert EDTF.humanize("{2019-06, 2020-06, 2021-06..2021-07}") ==
               "June 2019, June 2020, and June 2021 to July 2021"

      assert EDTF.humanize("{..1984}") == "all years before 1984 and 1984"
      assert EDTF.humanize("{1984..}") == "1984 and all years after 1984"
    end

    test "season" do
      assert EDTF.humanize("2020-21") == "Spring 2020"
      assert EDTF.humanize("2020-22") == "Summer 2020"
      assert EDTF.humanize("2020-23") == "Autumn 2020"
      assert EDTF.humanize("2020-24") == "Winter 2020"
      assert EDTF.humanize("2020-25") == "Spring (Northern Hemisphere) 2020"
      assert EDTF.humanize("2020-26") == "Summer (Northern Hemisphere) 2020"
      assert EDTF.humanize("2020-27") == "Autumn (Northern Hemisphere) 2020"
      assert EDTF.humanize("2020-28") == "Winter (Northern Hemisphere) 2020"
      assert EDTF.humanize("2020-29") == "Spring (Southern Hemisphere) 2020"
      assert EDTF.humanize("2020-30") == "Summer (Southern Hemisphere) 2020"
      assert EDTF.humanize("2020-31") == "Autumn (Southern Hemisphere) 2020"
      assert EDTF.humanize("2020-32") == "Winter (Southern Hemisphere) 2020"
      assert EDTF.humanize("2020-33") == "Quarter 1 2020"
      assert EDTF.humanize("2020-34") == "Quarter 2 2020"
      assert EDTF.humanize("2020-35") == "Quarter 3 2020"
      assert EDTF.humanize("2020-36") == "Quarter 4 2020"
      assert EDTF.humanize("2020-37") == "Quadrimester 1 2020"
      assert EDTF.humanize("2020-38") == "Quadrimester 2 2020"
      assert EDTF.humanize("2020-39") == "Quadrimester 3 2020"
      assert EDTF.humanize("2020-40") == "Semestral 1 2020"
      assert EDTF.humanize("2020-41") == "Semestral 2 2020"
    end

    test "intervals with seasons" do
      assert EDTF.humanize("1995-24/1996-22") == "Winter 1995 to Summer 1996"
      assert EDTF.humanize("-1995-24/1996-22") == "Winter 1995 BCE to Summer 1996"
    end
  end
end
