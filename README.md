# Tools

[syft](https://github.com/anchore/syft) - generate sboms from images. used by default with buildkit
[grype](https://github.com/anchore/grype) - scan an sbom
[Docker attestations](https://docs.docker.com/build/attestations/) -  create sbom and provenance from docker build
[conftest](https://github.com/open-policy-agent/conftest) - better way to write rego


## docker buildkit

requires having containerd as the image store for docker desktop enable to be able to store and push the attestations

with buildkit the attestations are stored within the layers of the image. this is different than how cosign works and the sigstore tooling. https://github.com/sigstore/cosign/issues/2688 

crane manifest dev.registry.tanzu.vmware.com/warroyo/buildkit-attest

provenance:

docker buildx imagetools inspect <namespace>/<image>:<version> \
    --format "{{ json .Provenance.SLSA }}"


sbom: 

docker buildx imagetools inspect <namespace>/<image>:<version> \
    --format "{{ json .SBOM.SPDX }}"


requires using opa cli to do verifications

opa eval -i buildkit-provenance.json -d validate-base.rego data.validate.allow --format pretty

## cosign

attaches artifacts to the images. this seems to be a more standard way that sigstore expects

docker build . -t dev.registry.tanzu.vmware.com/warroyo/cosign-attest


need to create provenance and sbom 

sbom
syft dev.registry.tanzu.vmware.com/warroyo/cosign-attest -o spdx-json > sbom.json


cosign attest --type spdxjson --predicate sbom.json --key cosign.key dev.registry.pivotal.io/warroyo/basic-build@sha256:7620cb34610ef908e5143eddc8093834d2dc8388e8188c1adee2497179162fb2 --tlog-upload=false

cosign download attestation \
  --predicate-type=https://spdx.dev/Document \
  dev.registry.tanzu.vmware.com/warroyo/cosign-attest | jq -r .payload | base64 -d | jq


cosign verify-attestation --key cosign.pub dev.registry.tanzu.vmware.com/warroyo/cosign-attest --insecure-ignore-tlog=true --type spdxjson

cosign verify-attestation --key cosign.pub dev.registry.tanzu.vmware.com/warroyo/cosign-attest --insecure-ignore-tlog=true --type spdxjson | jq -r .payload | base64 -D | jq . > att.json


cosign verify-attestation --key cosign.pub dev.registry.tanzu.vmware.com/warroyo/cosign-attest --insecure-ignore-tlog=true --type spdxjson | jq -r .payload | base64 -D | jq -r .predicate | grype

## combined

docker buildx imagetools inspect dev.registry.tanzu.vmware.com/warroyo/buildkit-attest  --format  "{{ json .SBOM.SPDX }}" > buildkit-sbom

docker buildx imagetools inspect dev.registry.tanzu.vmware.com/warroyo/buildkit-attest  --format "{{ json .Provenance.SLSA }}" >buildkit-provenance.json

then attest with cosign

cosign attest --type spdxjson --predicate buildkit-sbom.json --key cosign.key dev.registry.pivotal.io/warroyo/buildkit-attest@sha256:80f18774e1b4dc6cc1ef7fb93e42a3b41083d2fb0e141047b05e6a0bd35e9923 --tlog-upload=false

cosign attest --type slsaprovenance --predicate buildkit-provenance.json --key cosign.key dev.registry.pivotal.io/warroyo/buildkit-attest@sha256:80f18774e1b4dc6cc1ef7fb93e42a3b41083d2fb0e141047b05e6a0bd35e9923 --tlog-upload=false