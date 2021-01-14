Library used for code generation for custom domain libraries within the Scorekeeper ecosystem.

## Usage

Your custom domain should have a dev_dependency on the scorekeeper_codegen package.
When you've defined your domain's aggregate(s), commands and events, you can generate the required 
`CommandHandler` and `EventHandler` implementations that are used by the `Scorekeeper` instance.

``` pub run build_runner build ```
