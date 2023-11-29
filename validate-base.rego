package validate

allow  {
   image := input.buildConfig.llbDefinition[0].op.Op.source.identifier
   regex.match(".*\\bubuntu:latest?\\b.*", image)
}