# Infrastructure

## Prerequisites

1. Ensure gcloud is installed and logged in

```
gcloud auth login
```

## Provision the Environment

1. Create the workstations

```
NUMBER_OF_ATTENDEES=40
./create-workstations.sh ${NUMBER_OF_ATTENDEES}
```

2. Create the clusters

```
./create-clusters.sh
```

## Recreate Clusters

1. Delete the clusters

```
./delete-clusters.sh
```

2. Create new clusters

```
./create-clusters.sh
```

## Delete the Environment

1. Delete the clusters

```
./delete-clusters.sh
```

2. Delete the workstations

```
./delete-workstations.sh
```