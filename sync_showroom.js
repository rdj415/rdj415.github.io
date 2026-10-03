const fs = require('fs');
const path = require('path');

const fileMap = {
  'raw-atomic': 'src/shared/SharedModules/AtomicBinding.luau',
  'raw-loader': 'src/shared/ModuleLoader.luau',
  'raw-anticheat': 'src/server/ServerModules/AntiCheatService.luau',
  'raw-ability': 'src/server/ServerModules/AbilityService.luau',
  'raw-interaction': 'src/client/Controllers/InteractionController.luau',
  'raw-zone': 'src/server/ServerModules/ZoneService.luau',
  'raw-buffer': 'src/shared/Packages/BufferUtil.luau',
  'raw-ai': 'src/server/ServerModules/AIService.luau',
  'raw-hitbox': 'src/server/ServerModules/HitboxService.luau',
  'raw-data': 'src/server/ServerModules/DataService.luau',
  'raw-scythe': 'src/shared/Packages/Scythe.luau',
  'raw-dungeon': 'src/server/ServerModules/DungeonGenerator.luau',
};

const keywords = new Set([
  'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for', 'function',
  'if', 'in', 'local', 'nil', 'not', 'or', 'repeat', 'return', 'then',
  'true', 'until', 'while', 'export', 'type', 'continue'
]);

const types = new Set([
  'string', 'number', 'boolean', 'any', 'thread', 'table', 'void',
  'Vector3', 'Vector2', 'CFrame', 'Instance', 'RBXScriptConnection',
  'Player', 'Model', 'Folder', 'BasePart', 'ProximityPrompt',
  'AnimationTrack', 'UnreliableRemoteEvent', 'RemoteEvent', 'ScopeId',
  'Destructor', 'CleanupTask', 'PlayerData', 'ViolationData', 'PlayerState',
  'HitboxRequest', 'HitResult', 'NPCStrategy', 'NPCState', 'AbilityDefinition',
  'AbilityConfigType', 'UpdateCallback', 'LifecycleUnit'
]);

const builtins = new Set([
  'print', 'warn', 'error', 'assert', 'pcall', 'xpcall', 'select', 'type', 'typeof',
  'tostring', 'tonumber', 'rawget', 'rawset', 'setmetatable', 'getmetatable', 'ipairs', 'pairs', 'next'
]);

function escapeHtml(text) {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#x27;');
}

function highlightLine(line) {
  // Check for whole line or trailing comment
  let commentIndex = -1;
  let inString = false;
  let stringChar = '';

  for (let i = 0; i < line.length; i++) {
    const c = line[i];
    if (inString) {
      if (c === '\\') {
        i++; // skip escaped
      } else if (c === stringChar) {
        inString = false;
      }
    } else {
      if (c === '"' || c === "'") {
        inString = true;
        stringChar = c;
      } else if (c === '-' && line[i + 1] === '-') {
        commentIndex = i;
        break;
      }
    }
  }

  let codePart = commentIndex >= 0 ? line.slice(0, commentIndex) : line;
  let commentPart = commentIndex >= 0 ? line.slice(commentIndex) : '';

  // Tokenize codePart
  let result = '';
  let i = 0;
  while (i < codePart.length) {
    const char = codePart[i];

    // String literal
    if (char === '"' || char === "'") {
      let str = char;
      const quote = char;
      i++;
      while (i < codePart.length) {
        const sc = codePart[i];
        str += sc;
        if (sc === '\\' && i + 1 < codePart.length) {
          i++;
          str += codePart[i];
        } else if (sc === quote) {
          i++;
          break;
        }
        i++;
      }
      result += `<span class="t-str">${escapeHtml(str)}</span>`;
      continue;
    }

    // Number literal (e.g. 123, 1_000, 0.5)
    if (/\d/.test(char) || (char === '.' && /\d/.test(codePart[i + 1] || ''))) {
      let num = '';
      while (i < codePart.length && /[\d_a-fA-FxX\.]/.test(codePart[i])) {
        num += codePart[i];
        i++;
      }
      result += `<span class="t-num">${num}</span>`;
      continue;
    }

    // Identifier / Keyword
    if (/[a-zA-Z_]/.test(char)) {
      let ident = '';
      while (i < codePart.length && /[a-zA-Z0-9_]/.test(codePart[i])) {
        ident += codePart[i];
        i++;
      }

      if (keywords.has(ident)) {
        result += `<span class="t-kw">${ident}</span>`;
      } else if (types.has(ident)) {
        result += `<span class="t-type">${ident}</span>`;
      } else if (builtins.has(ident)) {
        result += `<span class="t-fn">${ident}</span>`;
      } else {
        // Check if followed by ( for function call
        let lookAhead = i;
        while (lookAhead < codePart.length && /\s/.test(codePart[lookAhead])) {
          lookAhead++;
        }
        if (codePart[lookAhead] === '(' && !['if', 'while', 'for', 'return'].includes(ident)) {
          result += `<span class="t-fn">${ident}</span>`;
        } else {
          result += ident;
        }
      }
      continue;
    }

    // Symbols & whitespace
    result += escapeHtml(char);
    i++;
  }

  if (commentPart) {
    result += `<span class="t-comment">${escapeHtml(commentPart)}</span>`;
  }

  return result;
}

function highlightLuau(source) {
  const lines = source.split(/\r?\n/);
  return lines.map(highlightLine).join('\n');
}

let htmlContent = fs.readFileSync('index.html', 'utf8');

for (const [tagId, relPath] of Object.entries(fileMap)) {
  const filePath = path.resolve(__dirname, relPath);
  if (!fs.existsSync(filePath)) {
    console.error(`File not found: ${filePath}`);
    continue;
  }
  const source = fs.readFileSync(filePath, 'utf8');
  const highlighted = highlightLuau(source);

  const regex = new RegExp(`(<code id="${tagId}">)[\\s\\S]*?(<\\/code>)`);
  if (!regex.test(htmlContent)) {
    console.error(`Tag id="${tagId}" not found in index.html!`);
    continue;
  }

  htmlContent = htmlContent.replace(regex, `$1${highlighted}$2`);
  console.log(`Updated ${tagId} from ${relPath}`);
}

fs.writeFileSync('index.html', htmlContent, 'utf8');
console.log('Successfully synchronized all 11 showroom blocks in index.html!');
