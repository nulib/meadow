# 25. ui-component-directory-structure

Date: 2020-05-06

## Status

Accepted

## Context

As front end projects grow, having a consistent directory structure and file naming patterns will help manage scaling and an understanding of what lives where.

## Decision

The general idea is that the component directory dictates its filename.

Say we have 2 folders under /assets/js/components/

- /assets/js/components/Work
- /assets/js/components/UI

Taking the Work components as an example, say we have a few components:

/assets/js/components/Work/List.js
/assets/js/components/Work/View.js

The "List" component should be defined in it's file something like:

```
const WorkList = () => <p>Im a component</p>;
```

and imported like such:

```
import React from 'react';
import WorkList from '../components/Work/List';
```

The actual filename (Name.jsx) of a component should ideally not have any camel casing or references to its parent directory.

## Consequences

This might seem overly verbose in the beginning, but in my experience it scales relatively well and makes searching for files in VSCode easier.
