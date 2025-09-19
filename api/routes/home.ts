import type { Request, Response } from 'express';
import YAML from 'yamljs';
import path from 'path';
import fs from 'fs';

const openapiPath = path.join(process.cwd(), 'public', 'openapi.yaml');

export const home = (req: Request, res: Response) => {
  try {
    if (!fs.existsSync(openapiPath)) {
      return res.status(500).json({ error: 'OpenAPI file not found' });
    }

    const doc = YAML.load(openapiPath);

    const routes = Object.entries(doc.paths || {}).flatMap(([route, methods]: [string, any]) => {
      return Object.entries(methods).map(([method, info]: [string, any]) => {
        const params = (info.parameters || []).map((p: any) => ({
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
      });
    });

    res.status(200).json(routes);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to parse OpenAPI file' });
  }
};
