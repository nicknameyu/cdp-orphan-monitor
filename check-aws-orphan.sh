#!/bin/hash

# Initialize variables
CDP_ENV_NAME=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --environment-name)
      CDP_ENV_NAME="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

while [ -z "$CDP_ENV_NAME" ]; do
  read -s -p "Enter CDP Environment Name: " CDP_ENV_NAME
  echo
done

CDP_INSTANCE_LIST=()
# Describe CDP environment and retrieve freeipa instance IDs, subnets
echo "[ INFO ]: Pulling CDP Environment info."
CDP_ENV_META=$(cdp environments describe-environment --environment-name $CDP_ENV_NAME)
if [ $? -ne 0 ]; then
    echo "[ FATAL ]: Failed describing environment $CDP_ENV_NAME. " 
    exit 3
fi

SUBNETS=$(echo $CDP_ENV_META|jq -r '.environment.network.subnetIds[]')

region=$(echo $CDP_ENV_META|jq -r .environment.region)

CDP_INSTANCE_LIST=$(echo $CDP_ENV_META|jq -r '.environment.freeipa.instances[].instanceId')

# Describe datalake to get instance IDs for datalake
echo "[ INFO ]: Pulling CDP Datalake $DATALAKE_NAME info."
DATALAKE_NAME=$(cdp datalake list-datalakes --environment-name $CDP_ENV_NAME|jq -r '.datalakes[].datalakeName')
if [ $? -ne 0 ]; then
    echo "[ FATAL ]: Failed to get datalake name from environment $CDP_ENV_NAME. " 
    exit 4
fi
DATALAKE_INSTANCES=$(cdp datalake describe-datalake --datalake-name $DATALAKE_NAME|jq -r '.datalake.instanceGroups[].instances[].id')
if [ $? -ne 0 ]; then
    echo "[ FATAL ]: Failed describing datalake $DATALAKE_NAME. " 
    exit 5
fi

CDP_INSTANCE_LIST="$CDP_INSTANCE_LIST
    $DATALAKE_INSTANCES"

# Retrieve DH clusters on this environments and get the list of instances 
echo "[ INFO ]: Pulling CDP Datahub instances."
DH_LIST=$(cdp datahub list-clusters --environment-name $CDP_ENV_NAME|jq -r '.clusters[].clusterName')
for datahub in $DH_LIST
do
    DH_INSTANCES=$(cdp datahub describe-cluster --cluster-name $datahub | jq -r '.cluster.instanceGroups[].instances[].id')
    echo Datahub instances for $datahub: 
    echo "$DH_INSTANCES"
    CDP_INSTANCE_LIST="$CDP_INSTANCE_LIST
        $DH_INSTANCES"
done
echo  CDP Instance List:
for instance in $CDP_INSTANCE_LIST
do
    echo "    $instance"
done


# Run AWS cli to get all the instances on the subnets of this CDP environmets.
echo "[ INFO ]: Pulling AWS instances on the CDP subnets."
filter=$(echo "$SUBNETS" | paste -sd "," -)

AWS_INSTANCES=$(aws ec2 describe-instances \
  --region "$region" \
  --filters "Name=subnet-id,Values=$filter" \
  --query 'Reservations[*].Instances[*].[InstanceId]'| jq -r '.[][][]')

if [ $? -ne 0 ]; then
    echo "[ FATAL ]: Failed pulling instances on the subnets"
    exit 6
fi
echo  AWS Instance List:
for instance in $AWS_INSTANCES
do
    echo "    $instance"
done
# Compare the two list.
## Clean the lists

CDP_INSTANCE_LIST=$(echo "$CDP_INSTANCE_LIST" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
AWS_INSTANCES=$(echo "$AWS_INSTANCES" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
## Compare the two list
ophan_list=$(echo "$AWS_INSTANCES" | grep -F -x -v -f <(echo "$CDP_INSTANCE_LIST"))

#Output the orphan list
if [ -z "$ophan_list" ];
then
    echo There isn\'t orphan servers on the CDP subnets.
else
    echo Ophan instances tags:
    for instance in $ophan_list
    do
        tags=$(aws ec2 describe-instances \
            --region "$region" \
            --instance-ids $instance \
            --query 'Reservations[*].Instances[*].[InstanceId,Tags]'| jq -r '.[][]')
        echo $tags | jq -r ' . as [$id, $tags] |$id + ": " + ($tags | map("\(.Key): \(.Value)") | join("; "))' 
    done
fi
