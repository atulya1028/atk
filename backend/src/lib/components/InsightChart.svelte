<script lang="ts">
    import { onMount } from 'svelte';
    import Chart from 'chart.js/auto';

    interface Insight {
        id: string;
        title: string;
        data: Record<string, number>;
    }

    let { data: items } = $props<{ data: Insight }>();
    let canvas: HTMLCanvasElement;

    onMount(() => {
        if (!canvas || !items) return;

        const labels = Object.keys(items.data);
        const dataValues = Object.values(items.data);
        const count = labels.length;

        const backgroundColors = labels.map((label, index) => {
            const l = label.toLowerCase();
            if (l === 'yes' || l.startsWith('yes ')) return '#fb7185'; 
            if (l === 'no' || l.startsWith('no ')) return '#4ade80'; 
            const accents = ['#38bdf8', '#818cf8', '#c084fc', '#f472b6', '#2dd4bf'];
            return accents[index % accents.length];
        });

        let type: any = 'bar';
        let indexAxis = 'x';

        if (count <= 2) {
             type = 'doughnut'; 
        } else if (count <= 5) {
             type = 'doughnut';
        } else {
             type = 'bar';
             indexAxis = 'y';
        }

        new Chart(canvas, {
            type: type,
            data: {
                labels: labels,
                datasets: [{
                    label: 'Count',
                    data: dataValues,
                    backgroundColor: backgroundColors,
                    borderWidth: 0,
                    borderRadius: type === 'bar' ? 4 : 0
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                indexAxis: indexAxis as any,
                plugins: {
                    legend: {
                        display: ['doughnut', 'pie'].includes(type),
                        position: 'right',
                        labels: { boxWidth: 10, font: { size: 10 }, color: '#94a3b8' }
                    }
                },
                scales: type === 'bar' ? {
                    [indexAxis === 'y' ? 'x' : 'y']: { beginAtZero: true, ticks: { stepSize: 1, color: '#94a3b8' } },
                    [indexAxis === 'y' ? 'y' : 'x']: { grid: { display: false }, ticks: { color: '#94a3b8' } }
                } : undefined
            }
        });
    });
</script>

<div class="bg-slate-800 rounded-xl p-6 border border-slate-700 shadow-lg mb-6">
    <div class="mb-4">
        <h3 class="text-gray-100 font-semibold text-lg leading-tight" title={items.title}>
            {items.title.length > 50 ? items.title.substring(0, 50) + '...' : items.title}
        </h3>
    </div>

    <div class="h-44 w-full relative">
        <canvas bind:this={canvas}></canvas>
    </div>

    <div class="mt-4 pt-2 border-t border-slate-700">
        <table class="w-full text-xs">
            <tbody>
                {#each Object.entries(items.data) as [label, count]}
                    <tr>
                        <td class="py-1 text-slate-400">{label}</td>
                        <td class="py-1 text-right font-semibold text-slate-200">{count}</td>
                    </tr>
                {/each}
            </tbody>
        </table>
    </div>
</div>
