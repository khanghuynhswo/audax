# audax deployment

## Overview

audax deployment chart is used to deploy audax modules using in cluster job.


### Prerequisites

- create secret with jwt token

```bash
apiVersion: v1
data:
  jwt.key: XXXXXX
kind: Secret
metadata:
  name: jwt-key-deployment
  namespace: audax-system
type: Opaque
```