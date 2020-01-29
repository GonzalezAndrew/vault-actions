#!/bin/bash

function readArgs() {

    if [ "${INPUT_VAULT_VERSION}" != "" ]; then
        vault_version=${INPUT_VAULT_VERSION}
    else
        echo "${INPUT_VAULT_VERSION}"
        echo "Input vault_version cannot be empty"
        exit 1
    fi

    if [ "${INPUT_VAULT_URL}" != "" ]; then
        vault_url=${INPUT_VAULT_URL}
    else
        echo "Input vault_url cannot be empty"
        exit 1
    fi

    if [ "${INPUT_VAULT_TOKEN}" != "" ]; then
        vault_token=${INPUT_VAULT_TOKEN}
    else
        echo "Input vault_token cannot be empty"
        exit 1
    fi

    if [ "${INPUT_SECRET_PATH}" != "" ]; then
        secret_path=${INPUT_SECRET_PATH}
    else
        echo "Input secret_path cannot be empty"
        exit 1
    fi

    if [ "${INPUT_AUTH_METHOD}" != "" ] || [ "${INPUT_AUTH_METHOD}" != "token" ]; then
        auth_method=${INPUT_AUTH_METHOD}
    fi

    if [ "${INPUT_SECRET_ID}" != "" ] || [ "${INPUT_SECRET_ID}" != "null" ]; then
        secret_id=${INPUT_SECRET_ID}
    fi

    if [ "${INPUT_ROLE_ID}" != "" ] || [ "${INPUT_ROLE_ID}" != "null" ]; then
        role_id=${INPUT_ROLE_ID}
    fi

    if [ "${INPUT_PASSWORD}" != "" ] || [ "${INPUT_PASSWORD}" != "null" ]; then
        password=${INPUT_PASSWORD}
    fi
}

function installVault() {
    url="https://releases.hashicorp.com/vault/${vault_version}/vault_${vault_version}_linux_amd64.zip"

    echo "Downloading Vault v${vault_version}"

    curl -s -S -L -o /tmp/vault_${vault_version} ${url}
    if [ "${?}" -ne 0 ]; then
        echo "Failed to download Vault v${vault_version}"
        exit 1
    fi
    echo "Successfully downloaded Vault v${vault_version}"

    echo "Unzipping Vault v${vault_version}"
    unzip -d /usr/local/bin /tmp/vault_${vault_version} &>/dev/null
    if [ "${?}" -ne 0 ]; then
        echo "Failed to unzip Vault v${vault_version}"
        exit 1
    fi
    echo "Successfully unzipped Vault v${vault_version}"
}

function isSealed() {
    vault status -address=$vault_url &>/dev/null
    if [ "${?}" -ne 0 ]; then
        echo "Your vault server is sealed. Please unseal it and try again."
        exit 1
    else
        return 0
    fi
}

function isInit() {
    if curl --silent "${vault_url}/v1/sys/init" | grep -q 'true'; then
        return 0
    else
        echo "Your vault server is not initialized. Please initialize your server and try again"
        exit 1
    fi
}

readArgs
installVault
isSealed
isInit

case "${auth_method}" in
userpass)
    vault login -address=$vault_url -method=userpass username=$vault_token password=$password
    vault kv get -address=$vault_url $secret_path
    ;;
approle)
    vault write -address=$vault_url auth/approle/login role_id=$role_id secret_id=$secret_id
    vault kv get -address=$vault_url $secret_path
    ;;
token)
    vault login -address=$vault_url ${vault_token}
    vault kv get -address=$vault_url $secret_path
    ;;
*)
    echo "An error has occured."
    exit 1
    ;;
esac
