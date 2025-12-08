# Qalculate! Calculator (qcalc) - Complete User Guide

A comprehensive guide for transitioning from Windows Calculator to the powerful qcalc command-line calculator.

## Installation

Qalculate! is included in your NixOS configuration via the `libqalculate` package, providing the `qalc` command-line interface.

## Quick Start

```bash
# Launch interactive calculator
qalc

# Perform single calculation
qalc "2 + 2"

# Exit interactive mode
quit
# or Ctrl+D
```

## Basic Arithmetic Operations

### Standard Operations
```bash
# Addition, subtraction, multiplication, division
qalc "15 + 27"          # 42
qalc "100 - 58"         # 42
qalc "6 * 7"            # 42
qalc "84 / 2"           # 42

# Exponentiation (power)
qalc "2^10"             # 1024
qalc "3^4"              # 81

# Square root and other roots
qalc "sqrt(64)"         # 8
qalc "cbrt(27)"         # 3 (cube root)
qalc "64^(1/3)"         # 4 (alternative cube root)
```

### Advanced Mathematical Functions
```bash
# Trigonometry (angles in radians by default)
qalc "sin(pi/2)"        # 1
qalc "cos(0)"           # 1
qalc "tan(pi/4)"        # 1

# Logarithms
qalc "log(100)"         # 2 (base 10)
qalc "ln(e)"            # 1 (natural log)
qalc "log2(8)"          # 3 (base 2)

# Constants
qalc "pi"               # 3.14159...
qalc "e"                # 2.71828...
qalc "c"                # Speed of light
```

## 📅 **DATE CALCULATIONS** - The Windows Calculator Replacement

### **Days Since a Specific Date**

This is one of the most powerful features for replacing Windows Calculator's date functions:

```bash
# Calculate days since a specific date (most common use case)
qalc "today - 2023-12-25"                    # Days since Christmas 2023
qalc "today - 1990-05-15"                    # Days since May 15, 1990
qalc "today - 2024-01-01"                    # Days since New Year 2024

# Calculate days between any two dates
qalc "2024-12-25 - 2024-01-01"               # Days from New Year to Christmas 2024
qalc "2025-06-15 - today"                    # Days until June 15, 2025 (negative = future)

# Calculate specific date + days
qalc "2024-01-01 + 100 days"                 # What date is 100 days after Jan 1, 2024?
qalc "today + 30 days"                       # What date is 30 days from today?
qalc "today - 90 days"                       # What date was 90 days ago?
```

### **Age Calculations**
```bash
# Calculate exact age in various units
qalc "today - 1985-03-22"                    # Age in days
qalc "(today - 1985-03-22) / 365.25"         # Age in years (accounting for leap years)
qalc "(today - 1985-03-22) / 7"              # Age in weeks
qalc "(today - 1985-03-22) / 30.44"          # Age in months (approximate)

# Calculate age on specific future/past date
qalc "2025-12-25 - 1985-03-22"               # Age on Christmas 2025
```

### **Project Timeline Calculations**
```bash
# Project duration
qalc "2024-06-30 - 2024-01-15"               # Project lasted how many days?

# Deadline calculations
qalc "today + 45 days"                       # 45-day deadline from today
qalc "2024-12-01 - today"                    # Days remaining until deadline

# Work day calculations (approximate)
qalc "(2024-06-30 - 2024-01-15) * (5/7)"     # Approximate work days (M-F)
```

### **Advanced Date Formats**
```bash
# Different date input formats (all equivalent)
qalc "today - 2024-03-15"                    # ISO format (recommended)
qalc "today - 2024/03/15"                    # Slash format
qalc "today - 15/03/2024"                    # European format
qalc "today - Mar 15, 2024"                  # Descriptive format

# Time calculations
qalc "now - 2024-03-15 14:30"                # Include time of day
qalc "today 18:00 - today 09:00"             # Work day duration
```

### **Recurring Date Calculations**
```bash
# Weekly/monthly patterns
qalc "today + 7 days"                        # Next week
qalc "today + 14 days"                       # Two weeks from now
qalc "today + 30 days"                       # Approximately next month

# Calculate intervals
qalc "today - (today - 365 days)"            # Days in the last year
qalc "((today - 2024-01-01) % 7) + 1"        # Day of week number
```

## Number Systems and Base Conversions

```bash
# Binary, octal, hexadecimal
qalc "bin(42)"          # Convert 42 to binary: 101010
qalc "oct(42)"          # Convert 42 to octal: 52
qalc "hex(42)"          # Convert 42 to hexadecimal: 2A

# Convert from other bases
qalc "0b101010"         # Binary to decimal: 42
qalc "0o52"             # Octal to decimal: 42
qalc "0x2A"             # Hexadecimal to decimal: 42
```

## Unit Conversions

```bash
# Length
qalc "5 feet to meters"           # 1.524 m
qalc "100 km to miles"            # 62.1371 miles
qalc "2.5 inches to cm"           # 6.35 cm

# Weight
qalc "150 lbs to kg"              # 68.0389 kg
qalc "2 kg to pounds"             # 4.40925 lbs

# Temperature
qalc "32 fahrenheit to celsius"   # 0°C
qalc "100 celsius to fahrenheit"  # 212°F
qalc "273.15 kelvin to celsius"   # 0°C

# Time
qalc "2 hours to minutes"         # 120 min
qalc "365 days to hours"          # 8760 hours
qalc "1 year to seconds"          # 31557600 seconds

# Data/Computing
qalc "1 GB to MB"                 # 1024 MB
qalc "500 MB to bytes"            # 524288000 bytes
qalc "1 TB to GB"                 # 1024 GB

# Currency (if exchange rates are available)
qalc "100 USD to EUR"             # Current exchange rate
qalc "50 GBP to USD"              # Current exchange rate
```

## Variables and Functions

```bash
# Define variables
qalc "x = 42"
qalc "y = x * 2"          # y = 84
qalc "x + y"              # 126

# Define custom functions
qalc "f(x) = x^2 + 2*x + 1"
qalc "f(5)"               # 36

# List variables and functions
qalc "variables"
qalc "functions"
```

## Statistical Functions

```bash
# Basic statistics
qalc "average([1, 2, 3, 4, 5])"     # 3
qalc "median([1, 2, 3, 4, 5])"      # 3
qalc "max([1, 5, 3, 9, 2])"         # 9
qalc "min([1, 5, 3, 9, 2])"         # 1
qalc "sum([1, 2, 3, 4, 5])"         # 15

# Standard deviation
qalc "stddev([2, 4, 4, 4, 5, 5, 7, 9])"   # Standard deviation
```

## Financial Calculations

```bash
# Percentage calculations
qalc "15% of 200"                   # 30
qalc "20 / 80 * 100"                # 25% (what percent is 20 of 80?)
qalc "200 * 1.15"                   # Add 15% (tax, tip, etc.)

# Interest calculations
qalc "1000 * (1 + 0.05)^10"         # Compound interest: $1000 at 5% for 10 years
qalc "1000 * 0.05 * 2"              # Simple interest: $1000 at 5% for 2 years

# Loan calculations (basic)
qalc "payment = principal * rate / (1 - (1 + rate)^(-months))"  # Define payment formula
qalc "principal = 200000; rate = 0.05/12; months = 30*12"       # Set loan parameters
qalc "payment"                      # Calculate monthly payment
```

## Useful Features for Daily Tasks

### Programming/Computing
```bash
# Bitwise operations
qalc "42 AND 15"                    # Bitwise AND: 10
qalc "42 OR 15"                     # Bitwise OR: 47
qalc "42 XOR 15"                    # Bitwise XOR: 37

# Modulo and integer division
qalc "42 mod 7"                     # 0
qalc "42 // 7"                      # 6 (integer division)
qalc "22 mod 7"                     # 1
```

### Quick Conversions
```bash
# Time zones (if configured)
qalc "now in UTC"                   # Current time in UTC
qalc "12:00 PST in EST"             # Convert time zones

# Cooking measurements
qalc "2 cups to ml"                 # 473.176 ml
qalc "350 fahrenheit to celsius"    # 176.667°C (oven temperature)
qalc "1 tablespoon to ml"           # 14.7868 ml
```

## Configuration and Settings

### Interactive Mode Settings
```bash
# Inside qcalc interactive mode:
set precision 10                    # Set decimal precision
set angle_unit degrees              # Use degrees instead of radians
set complex_form polar              # Set complex number format
save                               # Save settings
```

### Output Formats
```bash
qalc "42" -t                       # Simple output without units
qalc "pi" -s                       # Scientific notation
qalc "1000000" -e                  # Engineering notation
```

## Tips for Windows Calculator Users

1. **Replace Windows Calculator hotkey**: Set up a system shortcut to launch `qalc` in a terminal
2. **Quick calculations**: Use `qalc "expression"` for one-off calculations without entering interactive mode
3. **History**: Use up/down arrows in interactive mode to access calculation history
4. **Copy results**: Results can be copied directly from terminal output
5. **Date calculations**: Much more powerful than Windows Calculator - can handle any date format and complex date arithmetic

## Common Error Solutions

```bash
# If dates don't work, try different formats:
qalc "today - date(2024, 3, 15)"   # Function format
qalc "days(today, 2024-03-15)"     # Days function

# For undefined variables or functions:
list variables                      # See what's defined
help functions                      # Get function help
```

## 🔢 **REVERSE POLISH NOTATION (RPN) MODE**

Qalculate! includes full support for RPN (Reverse Polish Notation), making it perfect for users familiar with HP calculators or who prefer postfix notation.

### **Activating RPN Mode**

```bash
# In interactive mode
qalc
> rpn on                           # Activates both RPN syntax and stack
> rpn stack                        # Enables RPN stack only
> rpn syntax                       # Enables RPN syntax only  
> rpn off                          # Disables RPN mode
```

### **Basic RPN Operations**

In RPN mode, you enter numbers first, then operators:

```bash
# Traditional: 5 + 3 = 8
# RPN: 5 3 +
> rpn on
> 5                                # Push 5 onto stack
> 3                                # Push 3 onto stack  
> +                                # Add top two stack items: result = 8
```

### **RPN Stack Management Commands**

```bash
# View the stack
> stack                            # Display all stack items

# Clear operations
> clear stack                      # Empty the entire stack
> pop                             # Remove top item from stack
> pop 2                           # Remove item at position 2

# Copy and move operations  
> copy                            # Duplicate top stack item
> copy 2                          # Copy item at position 2 to top
> move 2 1                        # Move item from position 2 to position 1
> swap                            # Swap top two stack items
> swap 1 3                        # Swap items at positions 1 and 3

# Rotate stack
> rotate                          # Rotate stack upward (1→2, 2→3, top→1)
> rotate down                     # Rotate stack downward (top←1, 1←2, 2←3)
```

### **RPN Calculation Examples**

#### **Basic Arithmetic**
```bash
> rpn on
> 15 27 +                         # 15 + 27 = 42
> 100 58 -                        # 100 - 58 = 42  
> 6 7 *                           # 6 × 7 = 42
> 84 2 /                          # 84 ÷ 2 = 42
> 2 10 ^                          # 2^10 = 1024
```

#### **Complex Expressions**
```bash
# Traditional: (5 + 3) × (10 - 2) = 64
# RPN: 5 3 + 10 2 - ×
> 5 3 +                           # Stack: [8]
> 10 2 -                          # Stack: [8, 8] 
> *                               # Stack: [64]

# Traditional: √((5² + 3²)) = √34 ≈ 5.83
# RPN: 5 2 ^ 3 2 ^ + sqrt
> 5 2 ^                           # Stack: [25]
> 3 2 ^                           # Stack: [25, 9]
> +                               # Stack: [34]
> sqrt                            # Stack: [5.83095...]
```

#### **Date Calculations in RPN**
```bash
# Days since a date: today - 2024-01-01
> today 2024-01-01 -              # Calculate days since New Year

# Age calculation: (today - birthdate) / 365.25  
> today 1990-05-15 -              # Days since birth
> 365.25 /                        # Convert to years
```

#### **Unit Conversions in RPN**
```bash
# Convert 100 km to miles: 100 km miles to
> 100 km miles to                 # 100 km converted to miles

# Temperature conversion: 32 fahrenheit celsius to
> 32 fahrenheit celsius to        # 32°F to Celsius
```

### **Memory Operations in RPN Mode**

```bash
# Memory functions work in RPN mode
> 42                              # Put 42 on stack
> MS                              # Store top of stack to memory
> clear stack                     # Clear stack
> MR                              # Recall memory to stack
> 10 +                            # Add 10 to recalled value: 52
```

### **Advanced RPN Stack Techniques**

#### **Stack Manipulation for Complex Calculations**
```bash
# Calculate: (a + b) × (a - b) = a² - b² 
# Where a = 7, b = 3
> 7                               # Stack: [7]
> copy                            # Stack: [7, 7] (duplicate a)
> 3                               # Stack: [7, 7, 3]  
> copy                            # Stack: [7, 7, 3, 3] (duplicate b)
> +                               # Stack: [7, 7+3] = [7, 10] (a+b)
> swap                            # Stack: [10, 7] 
> swap 1 3                        # Arrange for subtraction
# Continue with subtraction and multiplication...
```

#### **Using Variables in RPN**
```bash
> x = 5                           # Define variable
> y = 3                           # Define variable  
> x y +                           # Use variables in RPN: 5 3 + = 8
```

### **RPN Mode Benefits**

1. **No Parentheses Needed**: Complex expressions don't require parentheses
2. **Stack-Based**: Natural for complex calculations with intermediate results
3. **HP Calculator Compatibility**: Familiar to HP calculator users
4. **Efficient Entry**: Fewer keystrokes for complex expressions
5. **Clear Operation Order**: Operations are always performed on stack top items

### **RPN vs Traditional Mode Comparison**

| Traditional Notation | RPN Notation | Result |
|---------------------|--------------|--------|
| `(5 + 3) * 2`       | `5 3 + 2 *`  | 16     |
| `sqrt(25)`          | `25 sqrt`    | 5      |
| `2^3 + 4^2`         | `2 3 ^ 4 2 ^ +` | 24  |
| `today - 2024-01-01`| `today 2024-01-01 -` | days |

### **RPN Tips for Efficiency**

1. **Start RPN in config**: Use `save mode` after `rpn on` to make it default
2. **Use stack command**: Frequently check stack status during complex calculations
3. **Plan ahead**: Think through the calculation order before starting
4. **Use copy liberally**: Duplicate values you'll need multiple times
5. **Practice basic patterns**: Master common sequences like `copy 2 ^ swap sqrt` for geometric means

### **Converting from Traditional to RPN**

**Rule**: Write the expression in the order you would evaluate it, placing operators after their operands.

```bash
# Traditional: ((2 + 3) * 4) - (5 / 2)
# Break down: 
#   1. 2 + 3 = 5
#   2. 5 * 4 = 20  
#   3. 5 / 2 = 2.5
#   4. 20 - 2.5 = 17.5
# RPN: 2 3 + 4 * 5 2 / -
```

RPN mode makes qcalc an extremely powerful calculator for users who prefer postfix notation or need to perform complex calculations with multiple intermediate results.

## Advanced Features

### Plotting (if GUI available)
```bash
# Plot functions
plot sin(x)                         # Plot sine wave
plot x^2                           # Plot parabola
```

### Unit System Management
```bash
# Custom units
1 myunit = 42 meters               # Define custom unit
qalc "5 myunit to feet"            # Use custom unit
```

## Conclusion

Qalculate! (`qcalc`) is significantly more powerful than Windows Calculator, especially for:
- **Date arithmetic** (days since/until dates, age calculations, project timelines)
- **Unit conversions** (length, weight, temperature, currency)
- **Scientific calculations** (trigonometry, logarithms, statistics)
- **Programming calculations** (base conversions, bitwise operations)
- **Financial calculations** (percentages, interest, loans)

The learning curve is minimal for basic operations, but the advanced features make it a replacement not just for Windows Calculator, but also for specialized calculation tools.

**Most Useful Command for Daily Use:**
```bash
qalc "today - YYYY-MM-DD"          # Calculate days since any date
```

This single pattern replaces most date-related tasks you'd use Windows Calculator for, and does them more accurately and flexibly.
