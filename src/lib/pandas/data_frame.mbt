///|
pub(all) struct DataFrame {
  mut data : Array[Series]
  mut shape : Array[Int]
  mut index : Map[String, Int]
}

///|
let emptyDataFrame : DataFrame = DataFrame::{
  data: [],
  shape: [0, 0],
  index: {},
}

///|
type! InconsistentSeriesLength String derive(Show)

///|
type! DuplicateColumnError String derive(Show)

///|
type! ColumnNotFoundError String derive(Show)

///|
type! IndexOutOfBounds String derive(Show)

///|
type! InvalidType String derive(Show)

///| Create a new DataFrame
///
/// # Parameters
///
/// - `data` : Array of Series
///
/// # Returns
///
/// - `DataFrame!InconsistentSeriesLength` : A new DataFrame instance
///
/// # Errors
///
/// - `InconsistentSeriesLength` : Raised if the lengths of the Series are not equal
///
/// # Example
/// ```
/// let df = DataFrame::new!([
///   Series::new("A", SeriesData::Int([1, 1, 3, 1, 1, 6])),
///   Series::new("B", SeriesData::Float([1.5, 2.0, 3.5, 4.0, 5.5, 6.0])),
///   Series::new("C", SeriesData::Bool([true, false, true, false, true, false])),
///   Series::new("D", SeriesData::Str(["a", "b", "c", "d", "e", "f"])),
/// ])
/// ```
pub fn DataFrame::new(
  data : Array[Series]
) -> DataFrame!InconsistentSeriesLength {
  let index : Map[String, Int] = {}
  for i = 0; i < data.length(); i = i + 1 {
    if data[i].data().length() != data[0].data().length() {
      raise InconsistentSeriesLength(
        "Could not create a new DataFrame. The Series lengths are not equal.",
      )
    }
    index[data[i].name()] = i
  }
  DataFrame::{ data, shape: [data[0].data().length(), data.length()], index }
}

///|
pub fn DataFrame::shape(self : DataFrame) -> Array[Int] {
  self.shape
}

///|
pub fn DataFrame::data(self : DataFrame) -> Array[Series] {
  self.data
}

///| Trait Show for DataFrame
pub impl Show for DataFrame with output(self, logger) {
  let mut row_str = "\t"
  for col in self.data {
    row_str = row_str + col.name() + "\t"
  }
  logger.write_string(row_str + "\n")
  row_str = ""
  for i = 0; i < self.shape()[0]; i = i + 1 {
    row_str += i.to_string() + "\t"
    for col in self.data {
      match col.data() {
        SeriesData::Int(vals) => row_str += vals[i].to_string() + "\t"
        SeriesData::Float(vals) => row_str += vals[i].to_string() + "\t"
        SeriesData::Bool(vals) => row_str += vals[i].to_string() + "\t"
        SeriesData::Str(vals) => row_str += vals[i] + "\t"
      }
    }
    row_str += "\n"
  }
  logger.write_string(row_str)
}

///| Display the first few rows of the DataFrame
///
/// # Parameters
///
/// - `self` : An instance of the DataFrame
///
/// # Returns
///
/// - `Unit` : This function prints the first few rows of the DataFrame
///
/// # Example
/// ```
/// df.head()
/// ```
pub fn DataFrame::head(self : DataFrame) -> Unit {
  let mut row_str = "\t"
  for col in self.data {
    row_str = row_str + col.name() + "\t"
  }
  row_str += "\n"
  for i = 0; i < @math.minimum(5, self.shape()[0]); i = i + 1 {
    row_str += i.to_string() + "\t"
    for col in self.data {
      match col.data() {
        SeriesData::Int(vals) => row_str += vals[i].to_string() + "\t"
        SeriesData::Float(vals) => row_str += vals[i].to_string() + "\t"
        SeriesData::Bool(vals) => row_str += vals[i].to_string() + "\t"
        SeriesData::Str(vals) => row_str += vals[i] + "\t"
      }
    }
    row_str += "\n"
  }
  println(row_str)
}

///| Add a new column to the DataFrame
///
/// # Parameters
///
/// - `self` : An instance of the DataFrame
/// - `col` : The Series to be added as a new column
///
/// # Returns
///
/// - `Unit!` : This function adds a new column to the DataFrame or raises an error
///
/// # Errors
///
/// - `InconsistentSeriesLength`: Series length is not equal to the DataFrame length
/// - `DuplicateColumnError`: Series name already exists
///
/// # Example
/// ```
/// let new_column = Series::new("B", SeriesData::Int([1, 2, 3]))
/// df.add_column(new_column)
/// ```
pub fn DataFrame::add_column(self : DataFrame, col : Series) -> Unit! {
  if col.data().length() != self.shape()[0] {
    raise InconsistentSeriesLength(
      "Could not add a new column to the DataFrame. The Series lengths are not equal.",
    )
  }
  if self.index.contains(col.name()) {
    raise DuplicateColumnError(
      "Could not add a new column to the DataFrame. The Series name already exists.",
    )
  }
  self.data += [col]
  self.shape = [self.shape()[0], self.shape()[1] + 1]
  self.index[col.name()] = self.shape()[1] - 1
}

///| Drop a column from the DataFrame
///
/// # Parameters
///
/// - `self` : An instance of the DataFrame
/// - `col_name` : The name of the column to be dropped
///
/// # Returns
///
/// - `Unit` : This function drops a column from the DataFrame
///
/// # Example
/// ```
/// df.drop_column("column_name")
/// ```
pub fn DataFrame::drop_column(
  self : DataFrame,
  col_name : String
) -> Unit!ColumnNotFoundError {
  match self.index.get(col_name) {
    Some(idx) => {
      let _ = self.data.remove(idx)
      self.index.remove(col_name)
      self.shape = [self.shape()[0], self.shape()[1] - 1]
      self.index.each(fn(k, v) { if v > idx { self.index[k] = v - 1 } })
    }
    None => raise ColumnNotFoundError("Column '\{col_name}' not found")
  }
}

///| Rename a column in the DataFrame
///
/// # Parameters
///
/// - `self` : An instance of the DataFrame
/// - `old_name` : The current name of the column to be renamed
/// - `new_name` : The new name for the column
///
/// # Returns
///
/// - `Unit` : This function renames a column in the DataFrame
/// 
/// # Errors
/// 
/// - `ColumnNotFoundError` : Raised if the column is not found
///
/// # Example
/// ```
/// test {
///   let mut df = DataFrame::new([Series::new("A", SeriesData::Int([1, 2]))])
///   df.rename("A", "B")
///   inspect!(df.data()[0].name(), context="B")
/// }
/// ```
pub fn DataFrame::rename_column(
  self : DataFrame,
  old_name : String,
  new_name : String
) -> Unit!ColumnNotFoundError {
  match self.index.get(old_name) {
    Some(idx) => self.data[idx].name = new_name
    None => raise ColumnNotFoundError("Column '\{old_name}' not found")
  }
}

///| Select a column from the DataFrame
///
/// # Parameters
///
/// - `self` : An instance of the DataFrame
/// - `col_name` : Column name to be selected
///
/// # Returns
///
/// - `Series` : Series contain selected columns
/// 
/// # Errors
/// 
/// - `ColumnNotFoundError` : Raised if a column is not found
///
/// # Example
/// ```
/// let col_selected = df.column("col_name")
/// ```
pub fn DataFrame::column(
  self : DataFrame,
  col_name : String
) -> Series!ColumnNotFoundError {
  match self.index.get(col_name) {
    Some(idx) => self.data[idx]
    None => raise ColumnNotFoundError("Column '\{col_name}' not found")
  }
}

///| Select specific columns from the DataFrame
///
/// # Parameters
///
/// - `self` : An instance of the DataFrame
/// - `cols` : An array of column names to be selected
///
/// # Returns
///
/// - `DataFrame` : A new DataFrame containing only the selected columns
/// 
/// # Errors
/// 
/// - `ColumnNotFoundError` : Raised if a column is not found
///
/// # Example
/// ```
/// let df_selected = df.select_columns(["col_name1", "col_name2"])
/// ```
pub fn DataFrame::select_columns(
  self : DataFrame,
  cols : Array[String]
) -> DataFrame!ColumnNotFoundError {
  let selected_cols : Array[Series] = []
  let index : Map[String, Int] = {}
  for name in cols {
    match self.index.get(name) {
      Some(idx) => {
        selected_cols.push(self.data[idx])
        index[name] = selected_cols.length() - 1
      }
      None => raise ColumnNotFoundError("Column '\{name}' not found")
    }
  }
  DataFrame::{
    data: selected_cols,
    shape: [self.shape()[0], selected_cols.length()],
    index,
  }
}

///| Drop a row from the DataFrame
///
/// # Parameters
///
/// - `self` : An instance of the DataFrame
/// - `row` : The index of the row to be dropped
///
/// # Returns
///
/// - `Unit` : This function drops a row from the DataFrame
///
/// # Errors
///
/// - `IndexOutOfBounds` : Raised if the row index is out of bounds
///
/// # Example
/// ```
/// df.drop_row(0)
/// ```
pub fn DataFrame::drop_row(self : DataFrame, row_index : Int) -> Unit! {
  if row_index < 0 || row_index >= self.shape()[0] {
    raise IndexOutOfBounds("Row index out of bounds")
  }
  for col in self.data {
    col.data.erase!(row_index)
  }
  self.shape[0] = self.shape[0] - 1
}

///| Add a new row to the DataFrame
///
/// # Parameters
///
/// - `self` : An instance of the DataFrame
/// - `row` : An array of DType representing the new row to be added
///
/// # Returns
///
/// - `Unit` : This function adds a new row to the DataFrame
///
/// # Errors
///
/// - `InconsistentSeriesLength` : Raised if the row length does not match the DataFrame column length
/// - `InvalidType` : if there is a type mismatch
///
/// # Example
/// ```
/// let mut df = DataFrame::new([
///   Series::new("A", SeriesData::Int([1, 2, 3])), 
///   Series::new("B", SeriesData::Float([1.1, 2.2, 3.3]))
/// ])
/// df.add_row([DType::Int(4), DType::Float(4.4)])
/// ```
pub fn DataFrame::add_row(self : DataFrame, row : Array[DType]) -> Unit! {
  if row.length() != self.shape()[1] {
    raise InconsistentSeriesLength(
      "Row length does not match DataFrame column length",
    )
  }
  for i = 0; i < row.length(); i = i + 1 {
    match self.data[i].data {
      SeriesData::Int(data) =>
        match row[i] {
          DType::Int(value) => data.push(value)
          _ => raise InvalidType("Type mismatch")
        }
      SeriesData::Float(data) =>
        match row[i] {
          DType::Float(value) => data.push(value)
          _ => raise InvalidType("Type mismatch")
        }
      SeriesData::Bool(data) =>
        match row[i] {
          DType::Bool(value) => data.push(value)
          _ => raise InvalidType("Type mismatch")
        }
      SeriesData::Str(data) =>
        match row[i] {
          DType::Str(value) => data.push(value)
          _ => raise InvalidType("Type mismatch")
        }
    }
  }
  self.shape[0] = self.shape[0] + 1
}

///| Select specific rows from the DataFrame
///
/// # Parameters
///
/// - `self` : An instance of the DataFrame
/// - `range` : An optional tuple representing the range of rows to be selected (inclusive start, exclusive end)
/// - `indices` : An optional array of row indices to be selected
///
/// # Returns
///
/// - `DataFrame` : A new DataFrame containing only the selected rows
/// 
/// # Errors
/// 
/// - `IndexOutOfBounds` : Raised if the row index is out of bounds
///
/// # Example
/// ```
/// let df_selected_range = df.select_rows(range=(1, 4))
/// 
/// let df_selected_indices = df.select_rows(indices=[1, 3, 5])
/// ```
pub fn DataFrame::select_rows(
  self : DataFrame,
  range? : (Int, Int),
  indices? : Array[Int]
) -> DataFrame!IndexOutOfBounds {
  match (range, indices) {
    (Some(_), Some(_)) | (Some(_), None) => {
      let selected_rows : Array[Series] = []
      for col in self.data {
        let (begin, end) = match range {
          Some(r) => r
          None => abort("Range is None")
        }
        let select_data = match col.data() {
          SeriesData::Int(data) =>
            SeriesData::Int(data.split_at(begin).1.split_at(end - begin).0)
          SeriesData::Float(data) =>
            SeriesData::Float(data.split_at(begin).1.split_at(end - begin).0)
          SeriesData::Bool(data) =>
            SeriesData::Bool(data.split_at(begin).1.split_at(end - begin).0)
          SeriesData::Str(data) =>
            SeriesData::Str(data.split_at(begin).1.split_at(end - begin).0)
        }
        selected_rows.push(Series::new(col.name(), select_data))
      }
      DataFrame::{
        data: selected_rows,
        shape: [selected_rows[0].data.length(), self.shape()[1]],
        index: self.index,
      }
    }
    (None, Some(_)) =>
      match indices {
        Some(i) => {
          i.sort()
          if i[0] < 0 || i[i.length() - 1] >= self.shape()[0] {
            raise IndexOutOfBounds("Row index out of bounds")
          }
          let selected_rows : Array[Series] = []
          for col in self.data {
            match col.data {
              SeriesData::Int(data) => {
                let col_data = []
                for idx in i {
                  col_data.push(data[idx])
                }
                selected_rows.push(
                  Series::new(col.name(), SeriesData::Int(col_data)),
                )
              }
              SeriesData::Float(data) => {
                let col_data = []
                for idx in i {
                  col_data.push(data[idx])
                }
                selected_rows.push(
                  Series::new(col.name(), SeriesData::Float(col_data)),
                )
              }
              SeriesData::Bool(data) => {
                let col_data = []
                for idx in i {
                  col_data.push(data[idx])
                }
                selected_rows.push(
                  Series::new(col.name(), SeriesData::Bool(col_data)),
                )
              }
              SeriesData::Str(data) => {
                let col_data = []
                for idx in i {
                  col_data.push(data[idx])
                }
                selected_rows.push(
                  Series::new(col.name(), SeriesData::Str(col_data)),
                )
              }
            }
          }
          DataFrame::{
            data: selected_rows,
            shape: [selected_rows[0].data().length(), self.shape()[1]],
            index: self.index,
          }
        }
        None => emptyDataFrame
      }
    (None, None) => emptyDataFrame
  }
}

///| Filter rows in the DataFrame based on a condition
///
/// # Parameters
///
/// - `self` : An instance of the DataFrame
/// - `name` : The name of the column to apply the filter on
/// - `f` : A function that takes a `DType` and returns a `Bool` indicating whether the row should be included
///
/// # Returns
///
/// - `DataFrame` : A new DataFrame containing only the rows that satisfy the condition
///
/// # Example
/// ```
/// let df = DataFrame::new([Series::new("A", SeriesData::Int([1, 2, 3, 4, 5, 6]))])
/// let filtered = df.filter("A", fn(x) -> Bool { x < DType::Int(3) })
/// ```
pub fn DataFrame::filter(
  self : DataFrame,
  name : String,
  f : (DType) -> Bool
) -> DataFrame! {
  match self.index.get(name) {
    Some(index) =>
      match self.data[index].data() {
        SeriesData::Int(data) => {
          let rows = Array::new()
          for i = 0; i < data.length(); i = i + 1 {
            if f(DType::Int(data[i])) {
              rows.push(i)
            }
          }
          self.select_rows!(indices=rows)
        }
        SeriesData::Float(data) => {
          let rows = Array::new()
          for i = 0; i < data.length(); i = i + 1 {
            if f(DType::Float(data[i])) {
              rows.push(i)
            }
          }
          self.select_rows!(indices=rows)
        }
        SeriesData::Bool(data) => {
          let rows = Array::new()
          for i = 0; i < data.length(); i = i + 1 {
            if f(DType::Bool(data[i])) {
              rows.push(i)
            }
          }
          self.select_rows!(indices=rows)
        }
        SeriesData::Str(data) => {
          let rows = Array::new()
          for i = 0; i < data.length(); i = i + 1 {
            if f(DType::Str(data[i])) {
              rows.push(i)
            }
          }
          self.select_rows!(indices=rows)
        }
      }
    None => emptyDataFrame
  }
}

///| Sort the DataFrame by a specified column
///
/// # Parameters
///
/// - `self` : An instance of the DataFrame
/// - `col_name` : The name of the column to sort by
/// - `decrease~` : Whether to sort in descending order (default is false)
///
/// # Returns
///
/// - `Unit` : This function sorts the DataFrame in place
///
/// # Errors
///
/// - `ColumnNotFoundError` : Raised if the specified column is not found
///
/// # Example
/// ```
/// let df = DataFrame::new([
///   Series::new("A", SeriesData::Int([3, 1, 2])), 
///   Series::new("B", SeriesData::Float([3.3, 1.1, 2.2]))
/// ])
/// df.sort("A", decrease=true)
/// inspect!(df.data()[0].data(), content="Int([1, 2, 3])")
/// ```
pub fn DataFrame::sort(
  self : DataFrame,
  col_name : String,
  decrease~ : Bool = false
) -> Unit!ColumnNotFoundError {
  match self.index.get(col_name) {
    Some(index) => {
      let indices = self.data[index].data.get_argsort_indices(decrease~)
      for item in self.data {
        item.data.argsort_indices(indices)
      }
    }
    None => raise ColumnNotFoundError("Column '\{col_name}' not found.")
  }
}

///| Tests
test "new" {
  let df = DataFrame::new!([
    Series::new("A", SeriesData::Int([1, 2, 3, 4, 5, 6])),
    Series::new("B", SeriesData::Float([1.5, 2.0, 3.5, 4.0, 5.5, 6.0])),
    Series::new("C", SeriesData::Bool([true, false, true, false, true, false])),
    Series::new("D", SeriesData::Str(["a", "b", "c", "d", "e", "f"])),
  ])
  inspect!(df.shape(), content="[6, 4]")
}

test "add_drop_rename" {
  let df = DataFrame::new!([
    Series::new("A", SeriesData::Int([1, 2, 3, 4, 5, 6])),
    Series::new("B", SeriesData::Float([1.5, 2.0, 3.5, 4.0, 5.5, 6.0])),
    Series::new("C", SeriesData::Bool([true, false, true, false, true, false])),
    Series::new("D", SeriesData::Str(["a", "b", "c", "d", "e", "f"])),
  ])
  df.add_column!(Series::new("E", SeriesData::Int([7, 8, 9, 10, 11, 12])))
  inspect!(df.shape(), content="[6, 5]")
  df.drop_column!("E")
  inspect!(df.shape(), content="[6, 4]")
  df.rename_column!("A", "A1")
  inspect!(df.data()[0].name(), content="A1")
  df.drop_row!(0)
  df.add_row!([
    DType::Int(7),
    DType::Float(7.5),
    DType::Bool(true),
    DType::Str("g"),
  ])
  inspect!(df.shape(), content="[6, 4]")
}

test "select" {
  let df = DataFrame::new!([
    Series::new("A", SeriesData::Int([1, 2, 3, 4, 5, 6])),
    Series::new("B", SeriesData::Float([1.5, 2.0, 3.5, 4.0, 5.5, 6.0])),
    Series::new("C", SeriesData::Bool([true, false, true, false, true, false])),
    Series::new("D", SeriesData::Str(["a", "b", "c", "d", "e", "f"])),
  ])
  let col_selected = df.select_columns!(["A", "B"])
  inspect!(col_selected.shape(), content="[6, 2]")
  let row_selected = df.select_rows!(range=(1, 3))
  inspect!(row_selected.shape(), content="[2, 4]")
  let row_selected = df.select_rows!(indices=[1, 3, 5])
  inspect!(row_selected.shape(), content="[3, 4]")
}

test "filter" {
  let df = DataFrame::new!([
    Series::new("A", SeriesData::Int([1, 1, 3, 1, 1, 6])),
    Series::new("B", SeriesData::Float([1.5, 2.0, 3.5, 4.0, 5.5, 6.0])),
    Series::new("C", SeriesData::Bool([true, false, true, false, true, false])),
    Series::new("D", SeriesData::Str(["a", "b", "c", "d", "e", "f"])),
  ])
  let filtered = df.filter!("A", fn(x) -> Bool { x < DType::Int(3) })
  inspect!(filtered.shape(), content="[4, 4]")
}

test "sort" {
  let df = DataFrame::new!([
    Series::new("A", SeriesData::Int([2, 1, 3, 5, 4])),
    Series::new("B", SeriesData::Float([2.2, 1.1, 3.3, 5.5, 4.4])),
    Series::new("C", SeriesData::Bool([true, false, true, false, true])),
    Series::new("D", SeriesData::Str(["b", "a", "c", "e", "d"])),
  ])
  df.sort!("A")
  inspect!(df.data()[0].data(), content="Int([1, 2, 3, 4, 5])")
  df.sort!("A", decrease=true)
  inspect!(df.data()[0].data(), content="Int([5, 4, 3, 2, 1])")
  inspect!(
    df.data()[3].data(),
    content="Str([\"e\", \"d\", \"c\", \"b\", \"a\"])",
  )
}

///|
test "new_error" {
  let col1 = Series::new("A", SeriesData::Int([1, 2, 3, 4, 5, 6]))
  let col2 = Series::new("B", SeriesData::Float([1.5, 2.0, 3.5]))
  let res = DataFrame::new?([col1, col2])
  inspect!(
    res,
    content="Err(InconsistentSeriesLength(\"Could not create a new DataFrame. The Series lengths are not equal.\"))",
  )
}

test "add_column_error" {
  let df = DataFrame::new!([
    Series::new("A", SeriesData::Int([1, 2, 3, 4, 5, 6])),
    Series::new("B", SeriesData::Float([1.5, 2.0, 3.5, 4.0, 5.5, 6.0])),
  ])
  let col = Series::new("B", SeriesData::Int([1, 2, 3, 4, 5, 6]))
  let res = df.add_column?(col)
  inspect!(
    res,
    content="Err(DuplicateColumnError(\"Could not add a new column to the DataFrame. The Series name already exists.\"))",
  )
  let res = df.add_column?(Series::new("C", SeriesData::Int([1, 2, 3])))
  inspect!(
    res,
    content="Err(InconsistentSeriesLength(\"Could not add a new column to the DataFrame. The Series lengths are not equal.\"))",
  )
}

test "drop_column_error" {
  let df = DataFrame::new!([
    Series::new("A", SeriesData::Int([1, 2, 3, 4, 5, 6])),
    Series::new("B", SeriesData::Float([1.5, 2.0, 3.5, 4.0, 5.5, 6.0])),
  ])
  let res = df.drop_column?("C")
  inspect!(res, content="Err(ColumnNotFoundError(\"Column 'C' not found\"))")
}

test "rename_column_error" {
  let df = DataFrame::new!([
    Series::new("A", SeriesData::Int([1, 2, 3, 4, 5, 6])),
    Series::new("B", SeriesData::Float([1.5, 2.0, 3.5, 4.0, 5.5, 6.0])),
  ])
  let res = df.rename_column?("C", "D")
  inspect!(res, content="Err(ColumnNotFoundError(\"Column 'C' not found\"))")
}
