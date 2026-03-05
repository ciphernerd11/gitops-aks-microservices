import React, { useState, useEffect, useCallback } from 'react';
import './App.css';

const API_BASE = '';
const REFRESH_INTERVAL = 15000;

const severityColors = {
    critical: '#f87171',
    high: '#fb923c',
    medium: '#fbbf24',
    low: '#4ade80',
};

function App() {
    const [alerts, setAlerts] = useState([]);
    const [resources, setResources] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [lastUpdated, setLastUpdated] = useState(null);

    const fetchData = useCallback(async () => {
        try {
            const [alertRes, resourceRes] = await Promise.allSettled([
                fetch(`${API_BASE}/alerts`),
                fetch(`${API_BASE}/resources`),
            ]);

            if (alertRes.status === 'fulfilled' && alertRes.value.ok) {
                const data = await alertRes.value.json();
                setAlerts(Array.isArray(data) ? data : data.alerts || []);
            }

            if (resourceRes.status === 'fulfilled' && resourceRes.value.ok) {
                const data = await resourceRes.value.json();
                setResources(Array.isArray(data) ? data : data.resources || []);
            }

            setLastUpdated(new Date());
            setError(null);
        } catch (err) {
            setError('Failed to fetch data. Retrying…');
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        fetchData();
        const interval = setInterval(fetchData, REFRESH_INTERVAL);
        return () => clearInterval(interval);
    }, [fetchData]);

    return (
        <div className="app">
            {/* ── Header ── */}
            <header className="header">
                <div className="header-inner">
                    <div className="logo">
                        <span className="logo-icon">🚨</span>
                        <div>
                            <h1>Disaster Relief HQ</h1>
                            <p className="subtitle">Real-Time Coordination Dashboard</p>
                        </div>
                    </div>
                    <div className="header-meta">
                        {lastUpdated && (
                            <span className="last-updated">
                                Updated {lastUpdated.toLocaleTimeString()}
                            </span>
                        )}
                        <span className={`status-badge ${error ? 'error' : 'ok'}`}>
                            {error ? '● Offline' : '● Live'}
                        </span>
                    </div>
                </div>
            </header>

            {/* ── Main Grid ── */}
            <main className="dashboard">
                {error && <div className="error-banner">{error}</div>}

                {loading ? (
                    <div className="loader">Loading…</div>
                ) : (
                    <div className="grid">
                        {/* Alerts Panel */}
                        <section className="card">
                            <div className="card-header">
                                <h2>🔔 Active Alerts</h2>
                                <span className="badge">{alerts.length}</span>
                            </div>
                            <div className="card-body">
                                {alerts.length === 0 ? (
                                    <p className="empty">No active alerts.</p>
                                ) : (
                                    <ul className="list">
                                        {alerts.map((a, i) => (
                                            <li key={a.id || i} className="list-item alert-item">
                                                <span
                                                    className="severity-dot"
                                                    style={{ background: severityColors[a.severity] || '#94a3b8' }}
                                                />
                                                <div className="item-content">
                                                    <strong>{a.title || 'Untitled Alert'}</strong>
                                                    <span className="meta">
                                                        {a.location || 'Unknown location'} · {a.severity || 'N/A'}
                                                    </span>
                                                </div>
                                                <time className="timestamp">
                                                    {a.created_at
                                                        ? new Date(a.created_at).toLocaleString()
                                                        : '—'}
                                                </time>
                                            </li>
                                        ))}
                                    </ul>
                                )}
                            </div>
                        </section>

                        {/* Resources Panel */}
                        <section className="card">
                            <div className="card-header">
                                <h2>📦 Resource Inventory</h2>
                                <span className="badge">{resources.length}</span>
                            </div>
                            <div className="card-body">
                                {resources.length === 0 ? (
                                    <p className="empty">No resources tracked.</p>
                                ) : (
                                    <table className="table">
                                        <thead>
                                            <tr>
                                                <th>Item</th>
                                                <th>Quantity</th>
                                                <th>Location</th>
                                                <th>Status</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            {resources.map((r, i) => (
                                                <tr key={r.id || i}>
                                                    <td>{r.name || '—'}</td>
                                                    <td>{r.quantity ?? '—'}</td>
                                                    <td>{r.location || '—'}</td>
                                                    <td>
                                                        <span className={`status ${r.status || 'unknown'}`}>
                                                            {r.status || 'unknown'}
                                                        </span>
                                                    </td>
                                                </tr>
                                            ))}
                                        </tbody>
                                    </table>
                                )}
                            </div>
                        </section>
                    </div>
                )}
            </main>
        </div>
    );
}

export default App;
