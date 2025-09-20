import * as YAML from 'yaml';
import * as path from 'path';
import * as fs from 'fs';
const openapiPath = path.join(process.cwd(), 'public', 'openapi.yaml');
export const home = (req, res) => {
    try {
        if (!fs.existsSync(openapiPath)) {
            res.status(500).json({ error: 'OpenAPI file not found' });
            return;
        }
        const fileContents = fs.readFileSync(openapiPath, 'utf8');
        const doc = YAML.parse(fileContents);
        const routes = Object.entries(doc.paths || {}).flatMap(([route, methods]) => Object.entries(methods).map(([method, info]) => {
            const params = (info.parameters || []).map((p) => ({
                name: p.name,
                in: p.in,
                required: p.required || false,
                type: p.schema?.type || 'string',
                description: p.description || '',
            }));
            return {
                method: method.toUpperCase(),
                route,
                summary: info.summary || '',
                description: info.description || '',
                tags: info.tags || [],
                parameters: params,
            };
        }));
        res.status(200).json(routes);
    }
    catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Failed to parse OpenAPI file' });
    }
};
