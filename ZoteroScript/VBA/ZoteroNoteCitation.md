# `ZoteroCitationAnchors`

---

## 🎯 **High-Level Overview**

The function **`ZoteroCitationAnchors`** generates a **string of citation items** following this pattern:

```html
<span class="citation-item"><a href="zotero://select/library/items/{ID}">“{Title}”</a></span>
```

The function accepts either:

- **Two parameters**: Two arrays of the same size or two single cells.  
- **One parameter**: A **2D array** with exactly **2 columns**.  

**Primary tasks:**  
1. **Validate inputs**.  
2. **Extract IDs and titles**.  
3. **Generate citation strings**.  
4. **Concatenate the results** using a **separator**.  

### **Return Value:**  
A single concatenated string of citation items.

---

## 🛠️ **Step-by-Step Logic**

---

### 🧩 **Input Parameters**

The function signature:

```vba
Public Function ZoteroCitationAnchors(rng1 As Variant, Optional rng2 As Variant) As String
```

- `rng1`: Required; can be **a single cell**, **a 1D array**, or **a 2D array**.  
- `rng2`: Optional; if provided, must be either **a single cell** or **a 1D array**.  

---

---

## 🛑 **Step 1: Parameter Analysis**

The function starts by determining whether **one or two arguments** have been passed.

### 🔍 **Code:**

```vba
If Not IsMissing(rng2) Then
```

- **If `rng2` exists** → We proceed with the **two-argument logic**.  
- **Otherwise**, we assume **one-argument logic**.

---

---

## 🔄 **Step 2: Two-Argument Logic**

### 🛠️ **Goal:**  
Use two **1D arrays** or two **single cells** to generate the citations.

### **Possible Scenarios:**

1. **Both parameters are single cells** → Wrap them in single-element arrays.  
2. **One parameter is an array and the other is a single value** → Raise an error.  
3. **Both are arrays but with different sizes** → Raise an error.  
4. **Both are arrays with equal sizes** → Use them directly.  

---

### 🔍 **Code:**

```vba
' Check if parameters are arrays
Dim isRng1Array As Boolean, isRng2Array As Boolean
isRng1Array = IsArray(rng1)
isRng2Array = IsArray(rng2)

' 1.1) Both single values
If Not isRng1Array And Not isRng2Array Then
    ReDim idArray(1 To 1)
    ReDim titleArray(1 To 1)
    idArray(1) = rng1
    titleArray(1) = rng2
```

**Explanation:**  
- If both are single cells → **wrap into arrays of size 1**.  

---

```vba
' 1.2) One array, one single value
ElseIf isRng1Array Xor isRng2Array Then
    Err.Raise vbObjectError + 2001, , "Error: If providing two arguments, both must be arrays or both must be single values."
```

**Explanation:**  
- If **one is an array and the other isn't**, we **raise an error**.  
- **Symmetry is required**: Either both are arrays or both are single cells.  

---

```vba
' 1.3) Both are arrays; check length
ElseIf UBound(rng1) - LBound(rng1) <> UBound(rng2) - LBound(rng2) Then
    Err.Raise vbObjectError + 2002, , "Error: Arrays must have the same length."
```

**Explanation:**  
- If **both are arrays** but **their lengths differ**, we **raise an error**.  
- We compare **upper and lower bounds** to ensure **matching array sizes**.  

---

```vba
' 1.4) Assign arrays directly
Else
    idArray = rng1
    titleArray = rng2
End If
```

**Explanation:**  
- If **none of the above errors are triggered**, we **assign the arrays directly**.  

---

---

## ⚙️ **Step 3: One-Argument Logic**

### 🛠️ **Goal:**  
Accept a **2D array** with **two columns** and separate it into **ID** and **title arrays**.

### **Steps:**  
1. **Detect if it's a 2D array**.  
2. **Validate the column count**.  
3. **Extract values into arrays**.

---

### 🔍 **Code:**

```vba
' Single-argument scenario; expect a 2D array with 2 columns
colCount = 0
On Error Resume Next
colCount = UBound(rng1.Value, 2) - LBound(rng1.Value, 2) + 1
On Error GoTo 0

If colCount <> 2 Then
    Err.Raise vbObjectError + 3001, , "Error: Single argument must be a 2D array with exactly 2 columns."
```

**Explanation:**  
- We use `On Error Resume Next` to check the **number of columns**.  
- If **not 2 columns**, we **raise an error**.  

---

```vba
' Extract IDs and titles from the 2D array
Dim rowCount As Long
rowCount = UBound(rng1.Value, 1) - LBound(rng1.Value, 1) + 1
ReDim idArray(1 To rowCount)
ReDim titleArray(1 To rowCount)

For i = 1 To rowCount
    idArray(i) = rng1.Value(i, 1)
    titleArray(i) = rng1.Value(i, 2)
Next i
```

**Explanation:**  
- **Calculate row count** by comparing **upper and lower bounds**.  
- Extract **ID values** from **column 1** and **titles** from **column 2**.  
- Store results in **1D arrays** for later processing.  

---

---

## 🖋️ **Step 4: Citation String Generation**

Once we have **matching arrays** of **IDs** and **titles**, we proceed to **generate the citation strings**.

### 🛠️ **Logic:**  
- For each **index `i`**:  
  - **Concatenate the ID and title** into an **HTML `<span>` element**.  
- Use a **separator** (`vbCrLf` by default) between items.  

---

### 🔍 **Code:**

```vba
' Generate the citation strings
For i = LBound(idArray) To UBound(idArray)
    If Len(result) > 0 Then result = result & separator
    result = result & "<span class=""citation-item""><a href=""zotero://select/library/items/" & idArray(i) & """>“" & titleArray(i) & "”</a></span>"
Next i
```

**Explanation:**  
- We use `&` for **string concatenation**.  
- Construct the **HTML string** by inserting the **ID into the link** and the **title into the link text**.  

---

---

## 🔍 **Step 5: Return the Result**

```vba
ZoteroCitationAnchors = result
```

**Explanation:**  
- The final **concatenated citation string** is returned to **Excel**.

---

---

## 🛠️ **Error Handling Summary**

The function raises the following **custom errors**:

| **Error Code** | **Condition**                              | **Message**                                                          |
|-----------------|-------------------------------------------|------------------------------------------------------------------------|
| `2001`          | One array and one single value             | *"If providing two arguments, both must be arrays or both must be single values."*  |
| `2002`          | Arrays of different lengths                | *"Arrays must have the same length."*                                    |
| `3001`          | Single argument doesn't have 2 columns     | *"Single argument must be a 2D array with exactly 2 columns."*            |

---

---

## 🧪 **Testing Scenarios**

### ✅ **Valid Cases**

#### 1. **Single 2D Array**

| **A**      | **B**                                  |
|------------|----------------------------------------|
| `5KH7R9RI` | `Guide: Properly picking and using MOSFETs!, 2016` |
| `U5TEN8DA` | `The Art of Electronics, 2015`           |
| `X1Y2Z3A4` | `Practical Electronics for Inventors, 2017` |

**Excel Formula:**  
```excel
=ZoteroCitationAnchors(A1:B3)
```

---

#### 2. **Two Arrays**

**Excel Formula:**  
```excel
=ZoteroCitationAnchors(A1:A3, B1:B3)
```

---

#### 3. **Single Cells**

**Excel Formula:**  
```excel
=ZoteroCitationAnchors("5KH7R9RI", "Guide: Properly picking and using MOSFETs!, 2016")
```

---

---

## 🚨 **Invalid Cases**

### ❌ **Mismatched Arrays**

```excel
=ZoteroCitationAnchors(A1:A3, B1:B2)
```
**Error:**  
*"Arrays must have the same length."*  

---

### ❌ **Mixed Array/Cell**

```excel
=ZoteroCitationAnchors(A1:A3, "Title")
```
**Error:**  
*"If providing two arguments, both must be arrays or both must be single values."*  

---

### ❌ **Invalid 2D Array**

- Pass a 2D array with **more or fewer columns**.  

**Error:**  
*"Single argument must be a 2D array with exactly 2 columns."*  

---

---

## 🏆 **Conclusion**

The code implements all requested logic:

1. **Flexible input handling**.  
2. **Robust error checks**.  
3. **Clean, well-structured output**.  

