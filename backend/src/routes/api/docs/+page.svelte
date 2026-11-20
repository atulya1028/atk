
<script lang="ts">
  import { onMount } from 'svelte';

  onMount(() => {

    const script = document.createElement('script');
    script.src = 'https://unpkg.com/swagger-ui-dist@5.9.1/swagger-ui-bundle.js';
    script.crossOrigin = 'anonymous';
    script.onload = () => {
      const swagger = (window as any).SwaggerUIBundle;
      if (!swagger) return;
      const ui = swagger({
        url: '/api/docs/openapi.json',
        dom_id: '#swagger-ui',
        deepLinking: true,
        presets: [

          swagger.presets.apis,

          swagger.SwaggerUIStandalonePreset
        ],
        layout: "BaseLayout"
      });
    };
    document.head.appendChild(script);

    const style = document.createElement('link');
    style.rel = 'stylesheet';
    style.href = 'https://unpkg.com/swagger-ui-dist@5.9.1/swagger-ui.css';
    document.head.appendChild(style);
  });
</script>

<svelte:head>
  <title>ATK API Documentation</title>
</svelte:head>

<div id="swagger-ui"></div>

<style>
 :global(body) {
    margin: 0;
    padding: 0;
    background: #fafafa;
  }
</style>
