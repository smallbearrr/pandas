///| Tests
test "series" {
  let series = Series::new("test", SeriesData::Int([1, 2, 3, 4, 5]))
  assert_eq!(series.name(), "test")
  assert_eq!(series.data(), SeriesData::Int([1, 2, 3, 4, 5]))
}

test "argsort_indices" {
  let series = Series::new("test", SeriesData::Int([2, 1, 3, 5, 4]))
  let indices = series.data.get_argsort_indices()
  inspect!(indices, content="[1, 0, 2, 4, 3]")
  let series = Series::new("test", SeriesData::Str(["a", "b", "c", "d", "e"]))
  inspect!(series.data.get_argsort_indices(), content="[0, 1, 2, 3, 4]")
}

test "argsort" {
  let series = Series::new("test", SeriesData::Int([2, 1, 3, 5, 4]))
  let indices = series.data.argsort()
  inspect!(indices, content="[1, 0, 2, 4, 3]")
}

test "series_add" {
  let a = Series::new("a", SeriesData::Float([1.5, 2, 3.5]))
  let b = Series::new("b", SeriesData::Int([4, 5, 6]))
  let c = a.data + b.data
  inspect!(c, content="Float([5.5, 7, 9.5])")
  let c = a + b
  inspect!(c, content="{name: \"a\", data: Float([5.5, 7, 9.5])}")
}

test "series_sub" {
  let a = Series::new("a", SeriesData::Float([1.5, 2, 3.5]))
  let b = Series::new("b", SeriesData::Int([4, 5, 6]))
  let c = a.data - b.data
  inspect!(c, content="Float([-2.5, -3, -2.5])")
  let c = a - b
  inspect!(c, content="{name: \"a\", data: Float([-2.5, -3, -2.5])}")
}

test "series_mul" {
  let a = Series::new("a", SeriesData::Float([1.5, 2, 3.5]))
  let b = Series::new("b", SeriesData::Int([4, 5, 6]))
  let c = a.data * b.data
  inspect!(c, content="Float([6, 10, 21])")
  let c = a * b
  inspect!(c, content="{name: \"a\", data: Float([6, 10, 21])}")
}

test "series_div" {
  let a = Series::new("a", SeriesData::Int([2, 4, 9]))
  let b = Series::new("b", SeriesData::Int([1, 2, 3]))
  let c = a.data / b.data
  inspect!(c, content="Int([2, 2, 3])")
  let c = a / b
  inspect!(c, content="{name: \"a\", data: Int([2, 2, 3])}")
}

test "Series::var/int" {
  let series = Series::new("test", SeriesData::Int([1, 2, 3, 4, 5]))
  inspect!(series.var!(), content="2.5")
}

test "Series::var/float" {
  let series = Series::new("test", SeriesData::Float([1.5, 2.0, 3.5, 4.0, 5.5]))
  series.var!() |> ignore
  // series.var!() |> println
  // 2.575
}

test "Series::var/ddof" {
  let series = Series::new("test", SeriesData::Float([1.5, 2.0, 3.5, 4.0, 5.0]))
  series.var!(ddof=1) |> ignore
  // series.var!(ddof=1) |> println
  // 2.075
}

test "panic Series::var/invalid_type" {
  let series = Series::new("test", SeriesData::Str(["a", "b", "c"]))
  ignore(series.var!())
}

test "panic Series::var/empty_array" {
  let series = Series::new("test", SeriesData::Int([]))
  ignore(series.var!())
}
