# Stack profile: dotnet-webapi

ASP.NET Core Web APIs (minimal APIs or controllers), .NET 8 or later, xUnit, NUnit or MSTest.

## Detect
A `*.sln` or `*.slnx` at the root (or one level down), plus a project using `Microsoft.NET.Sdk.Web`.

## Config defaults (for `/aidlc-forge:init`)
| Key | Value |
|---|---|
| build | `dotnet build <sln> --nologo` |
| test_all | `dotnet test <sln> --nologo` |
| test_fast | If there are separate unit-test projects (`*.UnitTests`, `*.Tests.Unit`, `*Domain*.Tests`): `dotnet test <that csproj> --nologo`. Otherwise: `dotnet test <sln> --nologo --filter "FullyQualifiedName!~Integration&FullyQualifiedName!~Endpoints"`, adjusted to the real integration test class or namespace names. Must take under 60 s. |
| test_story | `dotnet test <sln> --nologo --filter "FullyQualifiedName~{ID}"` |
| format_file | `dotnet format whitespace --folder --include {FILE}` |
| run | `dotnet run --project <web csproj>` |
| code_dirs | `src tests` (or wherever the projects actually live) |
| test_dirs | `tests` |
| code_exts | `cs csproj` |
| contract | `docs/baseline/api/openapi.yaml` |

## Conventions agents follow (unless the codebase clearly does otherwise; then follow the codebase)
- **Layering:** endpoints and controllers only map HTTP. Business rules live in services or handlers and the
  domain, with no ASP.NET types in the domain.
- **Errors:** expected failures are values (a Result or error type) mapped once to RFC 9457 ProblemDetails,
  with a stable `code` extension. Exceptions are for programmer errors only.
- **Time:** inject `TimeProvider`. Never call `DateTime.Now` or `DateTimeOffset.UtcNow` in business code.
- **Build hygiene:** nullable enabled. `TreatWarningsAsErrors` if the repo already uses it. Don't add new warnings.
- **Packages:**
  - With `Directory.Packages.props` (central package management), add versions there only.
  - A new package needs an ADR, and is a hard stop in auto mode.
- **Persistence (EF Core):** add migrations with `dotnet ef migrations add <Name>`. Never apply them to
  non-local databases. Use parameterised queries only.
- **Concurrency:** check-then-write rules (uniqueness, balances, overlaps) must be atomic, through a
  transaction, constraint or lock. Name the mechanism in the design.
- **Architecture tests** (NetArchTest or ArchUnitNET) are part of the regression and must stay green.
- **Modular monoliths:** one unit should stay inside one module where possible. Cross-module calls go only
  through the module's public contracts.

## Testing
- **Unit tests:** the domain and services, with a fake `TimeProvider` (`FixedTimeProvider : TimeProvider`
  overriding `GetUtcNow`) and no I/O.
- **Integration tests:** `WebApplicationFactory<Program>` (needs `public partial class Program;`). Use a fresh
  factory or database per test class when state leaks. Use `ConfigureTestServices` to replace `TimeProvider` and
  external clients.
- **Assertions:** status codes, `application/problem+json`, the `code` value, the Location header on 201,
  and the resulting state.
- **Names:** `US006_AC04_<Behaviour>`. Use `[Theory]` / `[InlineData]` for value tables.
