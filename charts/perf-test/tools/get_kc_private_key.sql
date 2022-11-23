select cc.value from component_config cc
                       join component c on cc.component_id = c.id
                       join realm r on r.id = c.realm_id
where r.name='test1' and c.name = 'rsa-generated' and cc.name = 'privateKey';
