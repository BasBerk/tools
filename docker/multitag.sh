#!/bin/bash
#simple just run:./multitag.sh team=iss application=test images='quay.io/prometheus/alertmanager','k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.0'
#team and application are required to get the path good on the remote.
#Images, all images in single quotes, comma seperated

for ARGUMENT in "$@"; do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)

    case "$KEY" in
    team) TEAM=${VALUE} ;;
    application) APPLICATION=${VALUE} ;;
    images) IMAGES=${VALUE} ;;
    *) ;;
    esac
done

IFS=', ' read -r -a array <<<"$IMAGES"
for IMAGE in "${array[@]}"; do
    echo "working on imgage $IMAGE"

    REPO='.azurecr.io' # <-----------------CHANGE ME

    function create_vars {
        ORGIMG=$(cut -d/ -f1 --complement <<<$IMAGE)
        #ORGIMG=${ORGIMG%?}

        if [[ $IMAGE == *":"* ]]; then
            echo "Image has version specified"
            VERSION=$(cut -d":" -f2- <<<$IMAGE)

            NEWTAG="${REPO}/${TEAM}/${APPLICATION}/$ORGIMG"
            IMG="${IMAGE}"
        else
            echo "no version spefified"
            NEWTAG="${REPO}/${TEAM}/${APPLICATION}/$ORGIMG:latest"
            IMG="${IMAGE}:latest"
        fi
    }

    function d_pull {
        docker pull $IMG
    }

    function d_tag {

        TAG=$(docker images $IMG -q)
        echo "Newtag =$NEWTAG AND Tag =$TAG"

        docker tag $TAG $NEWTAG

    }

    function d_push {
        docker push $NEWTAG
    }

    create_vars && d_pull && d_tag && d_push
    unset VERSION
done
