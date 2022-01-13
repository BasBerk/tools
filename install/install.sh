for ARGUMENT in "$@"; do
    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)

    case "$KEY" in
    topics) topics=${VALUE} ;;
    *) ;;
    esac
done

IFS=', ' read -r -a array <<<"$topics"
for topic in "${array[@]}"; do
    if [[ $topic = "azure" ]]; then
        # whatever you want to do when topics contains value
    elif [[ $topic = "k8s" ]]; then
        # whatever you want to do when topics contains value
        echo "$topic is valid"
    else
        echo "$topic is invalid"
    fi
done
