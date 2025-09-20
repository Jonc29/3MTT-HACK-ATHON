import type { Request, Response } from 'express';
import * as YAML from 'yaml';
import * as path from 'path';
import * as fs from 'fs';

const openapiPath = path.join(process.cwd(), 'public', 'openapi.yaml');

interface Parameter {
  name: string;
  in: string;
  required: boolean;
  type: string;
  description: string;
}

interface Route {
  method: string;
  route: string;
  summary: string;
  description: string;
  tags: string[];
  parameters: Parameter[];
}

export const home = (req: Request, res: Response): void => {
  try {
    if (!fs.existsSync(openapiPath)) {
      res.status(500).json({ error: 'OpenAPI file not found' });
      return;
    }

    const fileContents = fs.readFileSync(openapiPath, 'utf8');
    const doc = YAML.parse(fileContents) as any;

    const routes: Route[] = Object.entries(doc.paths || {}).flatMap(
      ([route, methods]: [string, any]) =>
        Object.entries(methods).map(([method, info]: [string, any]) => {
          const params: Parameter[] = (info.parameters || []).map((p: any) => ({
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
        })
    );

    res.status(200).json(routes);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to parse OpenAPI file' });
  }
};
