# HalfSpaceTrees

![](https://github.com/e-k-m/HalfSpaceTrees.jl/workflows/ci/badge.svg)

> half space trees for anomaly detection 

[Installation](#installation) | [Examples](#examples) | [API](#api)

This package implements half space trees for anomaly detection. 
Half space trees are an online variant of isolation forests. They work 
well when anomalies are spread out. However, they do not work well 
if anomalies are packed together in windows. The main feature of this
package are:

- Learn and score single features.

- Support features with missing values.

## Installation

```julia-repl
pkg> add HalfSpaceTrees
```

## Examples

```julia
using HalfSpaceTree
x = [Dict("x" => e, "y" => e, "z" => e) for e in [0.5, 0.45, 0.43, 0.44, 0.445, 0.45, 0.0]]
hst = HalfSpaceTree(ntrees=10, height=3, windowsize=3)
for e in x[1:3]
    learn!(hst, e)
end
score(hst, x[end - 1]) < 0.5
```

## API

```text
HalfSpaceTree
learn!
score
```