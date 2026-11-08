--Server-side registry of downloaded Luau chunks.
--!strict

local HttpService = game:GetService("HttpService")

local RequiredModules = require(script.Parent:WaitForChild("GitHubModuleList") :: ModuleScript) :: {string}
local BundleFormat = "basic-system-server-v1"
local MaxBundleBytes = 900_000

type ModuleChunk = (ModuleScript) -> any
local CompiledModules: {[string]: ModuleChunk}? = nil
local Runtime = {}

local function GetBundleUrl(Repository: string, Ref: string): string
    assert(type(Repository) == "string" and Repository ~= "YOUR-USERNAME/YOUR-REPO",
        "Set Repository in BasicSystemGitHubSettings to your GitHub owner/repo.")
    local Owner, Repo = Repository:match("^([%w%-]+)/([%w_.%-]+)$")
    assert(Owner and Repo and Repo ~= "." and Repo ~= "..", "Repository must be a GitHub owner/repo.")
    assert(type(Ref) == "string", "Ref must be a GitHub branch name or full commit SHA.")
    local IsCommit = #Ref == 40 and Ref:match("^%x+$") ~= nil
    if not IsCommit then
        assert(Ref:match("^[%w_][%w_.%/-]*$") and not Ref:find("..", 1, true)
            and Ref:sub(-1) ~= "/", "Ref must be a GitHub branch name or full commit SHA.")
    end
    local PathRef = if IsCommit then Ref else `refs/heads/{Ref}`
    return `https://raw.githubusercontent.com/{Owner}/{Repo}/{PathRef}/Basic-System.server.json`
end

local function DownloadBundle(Url: string): string
    for Attempt = 1, 2 do
        local Success, Response = pcall(HttpService.RequestAsync, HttpService, {
            Url = Url,
            Method = "GET",
        })
        if Success and Response.Success then
            return Response.Body
        end
        if Success and Response.StatusCode < 500 and Response.StatusCode ~= 429 then
            error(`GitHub returned HTTP {Response.StatusCode}. Check the repository, ref, and Basic-System.server.json.`)
        end
        if Attempt == 2 then
            local Reason = if Success then `HTTP {Response.StatusCode}` else tostring(Response)
            error(`Could not download the GitHub bundle. Check Allow HTTP Requests and repository access. {Reason}`)
        end
        task.wait(1)
    end
    error("GitHub download did not complete.")
end

function Runtime.Load(Repository: string, Ref: string): ()
    assert(not CompiledModules, "The GitHub bundle is already loaded.")
    local CanCompile, Probe = pcall(function()
        return loadstring("return true")
    end)
    assert(CanCompile and type(Probe) == "function", "Enable LoadStringEnabled on ServerScriptService in Studio.")

    local Body = DownloadBundle(GetBundleUrl(Repository, Ref))
    assert(#Body <= MaxBundleBytes, "The GitHub bundle exceeds the supported size.")
    local Decoded, Bundle = pcall(HttpService.JSONDecode, HttpService, Body)
    assert(Decoded and type(Bundle) == "table" and Bundle.format == BundleFormat and type(Bundle.modules) == "table",
        "Expected a Basic System server bundle. Upload Basic-System.server.json to the configured repo.")

    --Prepare every chunk before the loader starts the admin system.
    local Prepared: {[string]: ModuleChunk} = {}
    for _, Key in RequiredModules do
        local Source = Bundle.modules[Key]
        assert(type(Source) == "string" and #Source > 0, `GitHub bundle is missing module {Key}.`)
        local Chunk, CompileError = loadstring("local script = ...\n" .. Source, "GitHub/" .. Key)
        assert(Chunk, `Cannot compile {Key}: {CompileError}`)
        Prepared[Key] = Chunk :: ModuleChunk
    end
    for Key in Bundle.modules do
        assert(Prepared[Key], `Unexpected GitHub module {Key}. Rebuild the Studio model for a changed module layout.`)
    end
    CompiledModules = Prepared
end

function Runtime.Run(Key: string, Module: ModuleScript): any
    local Modules = assert(CompiledModules, "Basic System's GitHub bundle has not been loaded.")
    local Chunk = assert(Modules[Key], `GitHub module {Key} is unavailable.`)
    return Chunk(Module)
end

return Runtime
