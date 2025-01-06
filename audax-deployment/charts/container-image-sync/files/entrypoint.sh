#! /bin/bash

get_ecr_token(){
  local AWS_REGION=$1
  aws ecr get-login-password --region $AWS_REGION > /opt/audax/container-image-sync/ecr-token
}

registry_login(){
  local REGISTRY=$1
  local REGISTRY_USER=$2
  local TOKEN_PATH=$3
  local BIN="${4:-skopeo}"
  echo "Attempting Registry Login.."
  cat $TOKEN_PATH | $BIN login $REGISTRY -u $REGISTRY_USER --password-stdin 
}

process_module_images(){
  local IMAGE_LIST='/opt/audax/container-image-sync/images.txt'
  yq '.*|to_entries|.[]|(.value.image.repository + ":" + .value.image.tag)' /opt/audax/container-image-sync/config/modules-definition.yaml | cut -f2 -d/ > $IMAGE_LIST
}

process_service_images(){
  local IMAGE_LIST='/opt/audax/container-image-sync/images.txt'
  yq '.*.*.*.image|(.repository + ":" + .tag)' /opt/audax/container-image-sync/services-definition.yaml | cut -f2 -d/ > $IMAGE_LIST
}

get_images(){
  cat '/opt/audax/container-image-sync/images.txt' 
}

create_image_repos(){
  local TARGET_REGISTRY_REGION={{ .Values.target.region }}
  local TARGET_REPO_PREFIX={{ .Values.target.repoPrefix }}
  local TARGET_REPO_CREATION={{ .Values.target.repoCreation }}
  if [[ $TARGET_REPO_CREATION == "true" ]]; then
    local images=`get_images`
    local repo_policy='/opt/audax/container-image-sync/config/repo-policy.json'
    local repo_lifecycle_policy='/opt/audax/container-image-sync/config/repo-lifecycle-policy.json'
    get_ecr_token $TARGET_REGISTRY_REGION
    for image in $images; do
      repo=`echo $image | awk -F: '{print $1}'`
      echo "Attempting Image Repo Creation: ${TARGET_REPO_PREFIX}/${repo}"
      aws ecr create-repository --repository-name ${TARGET_REPO_PREFIX}/${repo} #>/dev/null 2>&1
      # aws ecr put-lifecycle-policy --repository-name ${TARGET_REPO_PREFIX}/${repo} --lifecycle-policy-text file://$repo_lifecycle_policy
      # aws ecr set-repository-policy --repository-name ${TARGET_REPO_PREFIX}/${repo} --policy-text file://$repo_policy #>/dev/null 2>&1 #TODO: required if client has multiple aws accounts.
    done
  fi
}

sync_images(){
  local SOURCE_REGISTRY={{ .Values.source.url }}
  local TARGET_REGISTRY={{ .Values.target.url}}
  local SOURCE_REPO_PREFIX={{ .Values.source.repoPrefix }}
  local TARGET_REPO_PREFIX={{ .Values.target.repoPrefix }}
  local SOURCE_REGISTRY_USER=`cat /opt/audax/container-image-sync/secret/ghcr-user`
  local TARGET_REGISTRY_USER=`cat /opt/audax/container-image-sync/secret/ecr-user`
  local images=`get_images`
  registry_login $SOURCE_REGISTRY $SOURCE_REGISTRY_USER '/opt/audax/container-image-sync/secret/ghcr-token'
  registry_login $TARGET_REGISTRY $TARGET_REGISTRY_USER '/opt/audax/container-image-sync/ecr-token'
  echo "Syncing module images.."
  for image in $images; do
    echo "Attempting Image Repo Sync: $image"
    skopeo copy docker://$SOURCE_REGISTRY/$SOURCE_REPO_PREFIX/$image docker://$TARGET_REGISTRY/$TARGET_REPO_PREFIX/$image
  done
}

usage() {
cat << EOF
  Usage:  [-h  | --help | -u | --usage]
          [-sm | --set-module-images]: sets module images from modules-definition
          [-ss | --set-service-images]: sets service images from services-definition
          [-cr | --create-repos]: creates ECR Image repositories
          [-si | --sync-images]: copies/syncs images from source to destination repos.
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help|-u|--usage)
            usage
            shift 
            ;;
        -sm|--process-module-images)
            process_module_images 
            shift 
            ;;
        -ss|--process-service-images)
            process_service_images 
            shift 
            ;;
        -cr|--create-image-repos)
            create_image_repos
            shift
            ;;
        -si|--sync-images)
            sync_images
            shift 
            ;;
        *) 
            echo "Error: Unknown option $1"
            usage
            exit 1
            ;;
    esac
done